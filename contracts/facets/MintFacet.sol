// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';
import {ERC721AUpgradeableInternal} from '../ERC721A-Contracts/ERC721AUpgradeableInternal.sol';
import {ONFTStorage} from '../ONFT-Contracts/ONFTStorage.sol';

import 'hardhat/console.sol';

contract MintFacet is ERC721AUpgradeableInternal {
    event DirtBikeCreated(uint indexed tokenId);

    uint public nextMintId;
    uint public maxMintId;

    function getHash() public view returns (uint256) {
        // generate psuedo-randomHash
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee)));

        return randomHash;
    }

    function mint(uint _amount) external payable {
        // uint256 dirtBikeHash = getHash();

        // DirtBikesStorage.dirtBikeslayout().tokenToHash[tokenId] = dirtBikeHash;
        for (uint i = 0; i < _amount; i++) {
            uint256 dirtBikeHash = getHash();
            uint256 tokenId = nextMintId + i;
            DirtBikesStorage.dirtBikeslayout().tokenToHash[tokenId] = dirtBikeHash;
            emit DirtBikeCreated(tokenId);
        }
        _safeMint(msg.sender, _amount, '');
    }
}
