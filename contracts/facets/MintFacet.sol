// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';
import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';
import {ONFTStorage} from '../layerZeroLibraries/ONFTStorage.sol';

import 'hardhat/console.sol';

contract MintFacet is ERC721Internal {
    event DirtBikeCreated(uint indexed tokenId);

    uint public nextMintId;
    uint public maxMintId;

    function getHash() public view returns (uint256) {
        // generate psuedo-randomHash
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee)));

        return randomHash;
    }

    function mint() external payable {
        uint256 dirtBikeHash = getHash();

        // TODO Update to revert
        require(
            ONFTStorage.oNFTStorageLayout().nextMintId <= ONFTStorage.oNFTStorageLayout().maxMintId,
            'UniversalONFT721: max mint limit reached'
        );

        uint newId = ONFTStorage.oNFTStorageLayout().nextMintId;
        ONFTStorage.oNFTStorageLayout().nextMintId++;

        // Store psuedo-randomHash as DirtBike VIN
        DirtBikesStorage.dirtBikeslayout().tokenToHash[newId] = dirtBikeHash;

        _safeMint(msg.sender, newId);
    }
}
