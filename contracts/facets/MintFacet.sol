// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';

contract MintFacet is ERC721Internal {
    function mint(address _tokenOwner, uint _newId) external payable {
        _safeMint(_tokenOwner, _newId);
    }
}
