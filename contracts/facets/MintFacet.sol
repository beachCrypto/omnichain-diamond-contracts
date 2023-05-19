// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DirtBikesStorage} from './DirtBikesStorage.sol';
import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';

import 'hardhat/console.sol';

contract MintFacet is ERC721Internal {
    event DirtBikeCreated(uint indexed tokenId);

    function getHash() public view returns (uint256) {
        // generate psuedo-randomHash
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee)));

        return randomHash;
    }

    function mint(address _tokenOwner, uint _tokenId) external payable {
        uint256 dirtBikeDNA = getHash();

        // Store psuedo-randomHash as DirtBike VIN
        DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[_tokenId] = dirtBikeDNA;

        _safeMint(_tokenOwner, _tokenId);
    }
}
