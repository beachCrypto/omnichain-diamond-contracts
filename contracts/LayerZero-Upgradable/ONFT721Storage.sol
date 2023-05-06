// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ONFT721Storage {
    struct ONFT721Info {
        address _lzEndpoint;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('beach-crypto.contracts.storage.ONFT721');

    function oNFT721Info() internal pure returns (ONFT721Info storage onfts) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            onfts.slot := slot
        }
    }
}
