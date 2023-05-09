// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import {IONFT721CoreUpgradeable} from './IONFT721CoreUpgradeable.sol';
import {ILayerZeroEndpoint} from '../layerZeroInterfaces/ILayerZeroEndpoint.sol';
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';
import {ONFT721UpgradeableInternal} from '../layerZeroUpgradeable/ONFT721UpgradeableInternal.sol';
import {NonblockingLzAppStorage} from './NonblockingLzAppStorage.sol';
import {ERC721AUpgradeableInternal} from '../ERC721A-Upgradeable/ERC721AUpgradeableInternal.sol';

contract ONFT721Upgradeable is ERC721AUpgradeableInternal, ONFT721UpgradeableInternal {
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _tokenId,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint nativeFee, uint zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(_toAddress, _tokenId);

        return
            LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                payload,
                _useZro,
                _adapterParams
            );
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable {
        _send(_from, _dstChainId, _toAddress, _tokenId, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        _debitFrom(_from, _dstChainId, _toAddress, _tokenId);

        bytes memory payload = abi.encode(_toAddress, _tokenId);
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, FUNCTION_TYPE_SEND, _adapterParams, NO_EXTRA_GAS);
        } else {
            require(_adapterParams.length == 0, 'LzApp: _adapterParams must be empty.');
        }
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams);

        uint64 nonce = LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.getOutboundNonce(
            _dstChainId,
            address(this)
        );
        emit SendToChain(_from, _dstChainId, _toAddress, _tokenId, nonce);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal virtual {
        // (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(_from);
        // // The nested ifs save around 20+ gas over a compound boolean condition.
        // if (!_isSenderApprovedOrOwner(approvedAddress, _tokenId, _msgSenderERC721A()))
        //     if (!_isApprovedForAll(_from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);
        // require(_ownerOf(_tokenId) == _from, 'ONFT721: send from incorrect owner');
        // _transfer(_from, address(this), _tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal virtual {
        // require(!_exists(_tokenId) || (_exists(_tokenId) && ERC721Upgradeable.ownerOf(_tokenId) == address(this)));
        // if (!_exists(_tokenId)) {
        //     _safeMint(_toAddress, _tokenId);
        // } else {
        //     _transfer(address(this), _toAddress, _tokenId);
        // }
    }

    function _checkGasLimit(uint16 _dstChainId, uint _type, bytes memory _adapterParams, uint _extraGas) internal view {
        // uint providedGasLimit = getGasLimit(_adapterParams);
        // uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        // require(minGasLimit > 0, 'LzApp: minGasLimit not set');
        // require(providedGasLimit >= minGasLimit, 'LzApp: gas limit is too low');
    }

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        bytes memory trustedRemote = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_dstChainId];

        require(trustedRemote.length != 0, 'LzApp: destination chain is not a trusted source');

        LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.send{value: msg.value}(
            _dstChainId,
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }
}
