// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import '../interfaces/ILayerZeroReceiverUpgradeable.sol';
import '../interfaces/ILayerZeroUserApplicationConfigUpgradeable.sol';
import '../interfaces/ILayerZeroEndpointUpgradeable.sol';
import {LzAppStorage} from './LzAppStorage.sol';
import {LibDiamond} from '../../libraries/LibDiamond.sol';
import {ERC721AUpgradeableInternal} from '../../ERC721A-Upgradeable/ERC721AUpgradeableInternal.sol';

/*
 * a generic LzReceiver implementation
 */
abstract contract LzAppUpgradeable is
    ERC721AUpgradeableInternal,
    ILayerZeroReceiverUpgradeable,
    ILayerZeroUserApplicationConfigUpgradeable
{
    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);
    event SetMinDstGasLookup(uint16 _dstChainId, uint _type, uint _dstGasAmount);

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security

        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        require(_msgSenderERC721A() == address(lzapp.lzEndpoint), 'LzApp: invalid endpoint caller');

        lzapp.trustedRemote = lzapp.trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == lzapp.trustedRemote.length &&
                keccak256(_srcAddress) == keccak256(lzapp.trustedRemote),
            'LzApp: invalid source sending contract'
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        lzapp.trustedRemote = lzapp.trustedRemoteLookup[_dstChainId];
        require(lzapp.trustedRemote.length != 0, 'LzApp: destination chain is not a trusted source');
        lzapp.lzEndpoint.send{value: msg.value}(
            _dstChainId,
            lzapp.trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function _checkGasLimit(uint16 _dstChainId, uint _type, bytes memory _adapterParams, uint _extraGas) internal view {
        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();
        uint providedGasLimit = getGasLimit(_adapterParams);
        uint minGasLimit = lzapp.minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, 'LzApp: minGasLimit not set');
        require(providedGasLimit >= minGasLimit, 'LzApp: gas limit is too low');
    }

    function getGasLimit(bytes memory _adapterParams) public pure returns (uint gasLimit) {
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint _configType
    ) external view returns (bytes memory) {
        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        return lzapp.lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external {
        LibDiamond.enforceIsContractOwner();

        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        lzapp.lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external {
        LibDiamond.enforceIsContractOwner();

        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        lzapp.lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external {
        LibDiamond.enforceIsContractOwner();

        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        lzapp.lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external {
        LibDiamond.enforceIsContractOwner();

        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        lzapp.lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external {
        LibDiamond.enforceIsContractOwner();
        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        lzapp.trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function setMinDstGasLookup(uint16 _dstChainId, uint _type, uint _dstGasAmount) external {
        LibDiamond.enforceIsContractOwner();
        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        require(_dstGasAmount > 0, 'LzApp: invalid _dstGasAmount');

        lzapp.minDstGasLookup[_dstChainId][_type] = _dstGasAmount;
        emit SetMinDstGasLookup(_dstChainId, _type, _dstGasAmount);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        LzAppStorage.LzAppStorageInfo storage lzapp = LzAppStorage.lzAppStorageInfo();

        bytes memory trustedSource = lzapp.trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}
