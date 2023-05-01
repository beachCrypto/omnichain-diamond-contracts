// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../ERC721A-Upgradeable/ERC721AUpgradeable.sol';

contract MintFacet is ERC721AUpgradeableInternal {
    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }
}
