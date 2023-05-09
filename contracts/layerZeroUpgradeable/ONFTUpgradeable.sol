// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import {NonblockingLzAppUpgradeable} from './NonblockingLzAppUpgradeable.sol';

contract ONFT721Upgradeable is NonblockingLzAppUpgradeable {
    // function estimateSendFee(uint16 _dstChainId, bytes memory _toAddress, uint _tokenId, bool _useZro, bytes memory _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
    //     // mock the payload for send()
    //     bytes memory payload = abi.encode(_toAddress, _tokenId);
    //     return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    // }
}
