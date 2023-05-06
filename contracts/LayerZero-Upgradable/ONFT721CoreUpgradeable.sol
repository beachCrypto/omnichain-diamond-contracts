// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import './ONFT721CoreUpgradeableInternal.sol';
import './ONFT721CoreStorage.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';

abstract contract ONFT721CoreUpgradeable is ONFT721CoreUpgradeableInternal, ONFT721CoreStorage {
    // =============================================================
    //                           PUBLIC CONSTANTS
    // =============================================================
    uint public constant NO_EXTRA_GAS = 0;

    uint public constant FUNCTION_TYPE_SEND = 1;

    bool public useCustomAdapterParams;

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

    function estimateSendFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        bool _useZro,
        bytes memory _adapterParams
    ) public view virtual returns (uint nativeFee, uint zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(_toAddress, _tokenId);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual {
        _send(_from, _dstChainId, _toAddress, _tokenId, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external {
        LibDiamond.enforceIsContractOwner();

        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }
}
