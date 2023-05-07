// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library NonblockingLzAppStorage {
    struct NonblockingLzAppInfo {
        mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) failedMessages;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('beach-crypto.contracts.storage.NonblockingLzApp');

    function nonblockingLzAppInfo() internal pure returns (NonblockingLzAppInfo storage nblklzapp) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            nblklzapp.slot := slot
        }
    }
}
