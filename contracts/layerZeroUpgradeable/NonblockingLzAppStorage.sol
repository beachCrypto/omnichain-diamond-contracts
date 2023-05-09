// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library NonblockingLzAppStorage {
    struct NonblockingLzAppSlot {
        mapping(uint16 => bytes) trustedRemoteLookup;
        mapping(uint16 => mapping(uint => uint)) minDstGasLookup;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('beachCrypto.omnichainDiamonds.storage.NonblockingLzApp');

    function nonblockingLzAppSlot() internal pure returns (NonblockingLzAppSlot storage nblks) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            nblks.slot := slot
        }
    }
}
