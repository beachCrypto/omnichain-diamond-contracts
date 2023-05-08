// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LayerZeroEndpointStorage {
    struct LayerZeroSlot {
        address royaltyReceiver;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('beachCrypto.omnichainDiamonds.storage.lZEndpoint');

    function layerZeroEndpointSlot() internal pure returns (LayerZeroSlot storage lzep) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            lzep.slot := slot
        }
    }
}
