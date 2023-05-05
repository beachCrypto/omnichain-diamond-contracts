// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LayerZeroStorage {
    struct LayerZeroInfo {
        address layerZeroEndpoint;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('beach-crypto.contracts.storage.LayerZero');

    function layerZeroInfo() internal pure returns (LayerZeroInfo storage lzl) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            lzl.slot := slot
        }
    }
}
