// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import {IONFT721CoreUpgradeable} from './IONFT721CoreUpgradeable.sol';

contract ONFT721Upgradeable is IONFT721CoreUpgradeable {
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _tokenId,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint nativeFee, uint zroFee) {}

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable override {}
}
