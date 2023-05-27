// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import './IONFT721CoreUpgradeable.sol';
import '../../contracts/layerZeroUpgradeable/NonblockingLzAppUpgradeable.sol';
import {ONFTStorage} from '../ONFT-Contracts/ONFTStorage.sol';

abstract contract ONFT721CoreUpgradeable is NonblockingLzAppUpgradeable {
    uint16 public constant FUNCTION_TYPE_SEND = 1;

    // function estimateSendFee(
    //     uint16 _dstChainId,
    //     bytes memory _toAddress,
    //     uint _tokenId,
    //     bool _useZro,
    //     bytes memory _adapterParams
    // ) public view virtual override returns (uint nativeFee, uint zroFee) {
    //     return estimateSendBatchFee(_dstChainId, _toAddress, _toSingletonArray(_tokenId), _useZro, _adapterParams);
    // }

    // function estimateSendBatchFee(
    //     uint16 _dstChainId,
    //     bytes memory _toAddress,
    //     uint[] memory _tokenIds,
    //     bool _useZro,
    //     bytes memory _adapterParams
    // ) public view virtual override returns (uint nativeFee, uint zroFee) {
    //     bytes memory payload = abi.encode(_toAddress, _tokenIds);
    //     return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    // }

    function setMinGasToTransferAndStore(uint256 _minGasToTransferAndStore) external {
        LibDiamond.enforceIsContractOwner();

        require(_minGasToTransferAndStore > 0, 'ONFT721: minGasToTransferAndStore must be > 0');
        ONFTStorage.oNFTStorageLayout().minGasToTransferAndStore = _minGasToTransferAndStore;
    }

    // ensures enough gas in adapter params to handle batch transfer gas amounts on the dst
    function setDstChainIdToTransferGas(uint16 _dstChainId, uint256 _dstChainIdToTransferGas) external {
        LibDiamond.enforceIsContractOwner();

        require(_dstChainIdToTransferGas > 0, 'ONFT721: dstChainIdToTransferGas must be > 0');
        ONFTStorage.oNFTStorageLayout().dstChainIdToTransferGas[_dstChainId] = _dstChainIdToTransferGas;
    }

    // limit on src the amount of tokens to batch send
    function setDstChainIdToBatchLimit(uint16 _dstChainId, uint256 _dstChainIdToBatchLimit) external {
        LibDiamond.enforceIsContractOwner();

        require(_dstChainIdToBatchLimit > 0, 'ONFT721: dstChainIdToBatchLimit must be > 0');
        ONFTStorage.oNFTStorageLayout().dstChainIdToBatchLimit[_dstChainId] = _dstChainIdToBatchLimit;
    }

    function _toSingletonArray(uint element) internal pure returns (uint[] memory) {
        uint[] memory array = new uint[](1);
        array[0] = element;
        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint[46] private __gap;
}
