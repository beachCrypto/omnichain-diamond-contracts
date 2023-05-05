// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ONFT721CoreStorage {
    struct ONFT721CoreInfo {
        // TO DO set state variables
        address ___;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('beach-crypto.contracts.storage.ONFT721Core');

    function oNFT721CoreInfo() internal pure returns (ONFT721CoreInfo storage onftcs) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            onftcs.slot := slot
        }
    }
}
