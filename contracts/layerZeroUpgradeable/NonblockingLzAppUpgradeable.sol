// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../libraries/LibDiamond.sol';
import '../layerZeroInterfaces/ILayerZeroReceiverUpgradeable.sol';
import '../layerZeroInterfaces/ILayerZeroUserApplicationConfig.sol';
import '../layerZeroInterfaces/ILayerZeroEndpoint.sol';
import {NonblockingLzAppStorage} from './NonblockingLzAppStorage.sol';
import '../utils/BytesLib.sol';
import '../utils/Context.sol';
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';
import 'hardhat/console.sol';
import {ONFTStorage} from '../ONFT-Contracts/ONFTStorage.sol';
import {IONFT721CoreUpgradeable} from '../ONFT-Contracts/IONFT721CoreUpgradeable.sol';

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzAppUpgradeable is
    Context,
    IONFT721CoreUpgradeable,
    ILayerZeroReceiverUpgradeable,
    ILayerZeroUserApplicationConfig
{
    using BytesLib for bytes;
    // ua can not send payload larger than this by default, but it can be changed by the ua owner

    uint public constant DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // LZAPP
    ILayerZeroEndpoint public lzEndpoint;

    function _storeFailedMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload,
        bytes memory _reason
    ) internal virtual {
        NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(
            _payload
        );
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        console.log('in nonblockingLzReceive __________');
        // only internal transaction
        require(_msgSender() == address(this), 'NonblockingLzApp: caller must be LzApp');
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal virtual {
        console.log('receive from chain');
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint[] memory tokenIds) = abi.decode(_payload, (bytes, uint[]));

        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        console.log('toAddress', toAddress);

        uint nextIndex = _creditTill(_srcChainId, toAddress, 0, tokenIds);

        console.log('nextIndex', nextIndex);

        if (nextIndex < tokenIds.length) {
            // not enough gas to complete transfers, store to be cleared in another tx
            bytes32 hashedPayload = keccak256(_payload);

            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload] = ONFTStorage.StoredCredit(
                _srcChainId,
                toAddress,
                nextIndex,
                true
            );
            emit CreditStored(hashedPayload, _payload);
        }

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenIds);
    }

    // When a srcChain has the ability to transfer more chainIds in a single tx than the dst can do.
    // Needs the ability to iterate and stop if the minGasToTransferAndStore is not met
    function _creditTill(
        uint16 _srcChainId,
        address _toAddress,
        uint _startIndex,
        uint[] memory _tokenIds
    ) internal returns (uint256) {
        console.log('in _creditTill');

        uint i = _startIndex;
        while (i < _tokenIds.length) {
            // if not enough gas to process, store this index for next loop
            if (gasleft() < ONFTStorage.oNFTStorageLayout().minGasToTransferAndStore) break;

            _creditTo(_srcChainId, _toAddress, _tokenIds[i]);
            i++;
        }

        // indicates the next index to send of tokenIds,
        // if i == tokenIds.length, we are finished
        return i;
    }

    function _creditTo(uint16 _srcChainId, address _toAddress, uint _tokenId) internal virtual;

    // //@notice override this function
    // function _nonblockingLzReceive(
    //     uint16 _srcChainId,
    //     bytes memory _srcAddress,
    //     uint64 _nonce,
    //     bytes memory _payload
    // ) internal virtual;

    // function retryMessage(
    //     uint16 _srcChainId,
    //     bytes calldata _srcAddress,
    //     uint64 _nonce,
    //     bytes calldata _payload
    // ) public payable virtual {
    //     // assert there is message to retry
    //     bytes32 payloadHash = NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][
    //         _nonce
    //     ];
    //     require(payloadHash != bytes32(0), 'NonblockingLzApp: no stored message');
    //     require(keccak256(_payload) == payloadHash, 'NonblockingLzApp: invalid payload');
    //     // clear the stored message
    //     NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
    //     // execute the message. revert if it fails again
    //     _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    //     emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    // }

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, 'LzApp: destination chain is not a trusted source');
        _checkPayloadSize(_dstChainId, _payload.length);
        LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.send{value: _nativeFee}(
            _dstChainId,
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
        console.log('in _lzSend');
    }

    function _checkGasLimit(
        uint16 _dstChainId,
        uint16 _type,
        bytes memory _adapterParams,
        uint _extraGas
    ) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = NonblockingLzAppStorage.nonblockingLzAppSlot().minDstGasLookup[_dstChainId][_type] +
            _extraGas;
        require(minGasLimit > 0, 'LzApp: minGasLimit not set');
        require(providedGasLimit >= minGasLimit, 'LzApp: gas limit is too low');
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, 'LzApp: invalid adapterParams');
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    // Nonblocking LZAPP

    // // allow owner to set it multiple times.
    // function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external {
    //     LibDiamond.enforceIsContractOwner();

    //     NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_srcChainId] = _srcAddress;

    //     emit SetTrustedRemote(_srcChainId, _srcAddress);
    // }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external {
        LibDiamond.enforceIsContractOwner();

        NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_remoteChainId] = abi.encodePacked(
            _remoteAddress,
            address(this)
        );
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, 'LzApp: no trusted path record');
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external {
        LibDiamond.enforceIsContractOwner();
        NonblockingLzAppStorage.nonblockingLzAppSlot().precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    // function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external {
    //     LibDiamond.enforceIsContractOwner();
    //     require(_minGas > 0, 'LzApp: invalid minGas');
    //     NonblockingLzAppStorage.nonblockingLzAppSlot().minDstGasLookup[_dstChainId][_packetType] = _minGas;
    //     emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    // }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external {
        LibDiamond.enforceIsContractOwner();

        NonblockingLzAppStorage.nonblockingLzAppSlot().payloadSizeLimitLookup[_dstChainId] = _size;
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = NonblockingLzAppStorage.nonblockingLzAppSlot().payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) {
            // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, 'LzApp: payload size is too large');
    }

    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override {}

    function setSendVersion(uint16 _version) external override {}

    function setReceiveVersion(uint16 _version) external override {}

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {}
}
