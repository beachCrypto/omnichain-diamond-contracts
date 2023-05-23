// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../libraries/LibDiamond.sol';
import '../layerZeroInterfaces/ILayerZeroReceiver.sol';
import '../layerZeroInterfaces/ILayerZeroUserApplicationConfig.sol';
import '../layerZeroInterfaces/ILayerZeroEndpoint.sol';
import {NonblockingLzAppStorage} from './NonblockingLzAppStorage.sol';
import '../utils/ExcessivelySafeCall.sol';
import '../utils/BytesLib.sol';

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzAppUpgradeable is ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    using ExcessivelySafeCall for address;
    // ua can not send payload larger than this by default, but it can be changed by the ua owner

    uint public constant DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    // LZAPP
    ILayerZeroEndpoint public lzEndpoint;

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external {
        LibDiamond.enforceIsContractOwner();

        NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_srcChainId] = _srcAddress;

        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

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

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external {
        LibDiamond.enforceIsContractOwner();
        require(_minGas > 0, 'LzApp: invalid minGas');
        NonblockingLzAppStorage.nonblockingLzAppSlot().minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

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
