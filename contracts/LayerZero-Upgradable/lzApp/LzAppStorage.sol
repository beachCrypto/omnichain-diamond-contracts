// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../interfaces/ILayerZeroEndpointUpgradeable.sol';

library LzAppStorage {
    struct LzAppStorageInfo {
        address _endpoint;
        ILayerZeroEndpointUpgradeable lzEndpoint;
        bytes trustedRemote;
        mapping(uint16 => bytes) trustedRemoteLookup;
        mapping(uint16 => mapping(uint => uint)) minDstGasLookup;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('beach-crypto.contracts.storage.LzAppStorage');

    function lzAppStorageInfo() internal pure returns (LzAppStorageInfo storage lzapp) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            lzapp.slot := slot
        }
    }
}
