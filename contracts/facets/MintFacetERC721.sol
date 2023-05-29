// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';
import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';
import {ONFTStorage} from '../layerZeroLibraries/ONFTStorage.sol';

import 'hardhat/console.sol';

contract MintFacetERC721 is ERC721Internal {
    event DirtBikeCreated(uint indexed tokenId);

    uint public nextMintId;
    uint public maxMintId;

    function getHash() public view returns (uint256) {
        // generate psuedo-randomHash
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee)));

        return randomHash;
    }

    function mint(address to, uint tokenId) public {
        uint256 dirtBikeHash = getHash();

        DirtBikesStorage.dirtBikeslayout().tokenToHash[tokenId] = dirtBikeHash;

        _safeMint(to, tokenId, '');
    }
}
