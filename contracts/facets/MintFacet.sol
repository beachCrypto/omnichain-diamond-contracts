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

    function mint(address _tokenOwner) external payable {
        nextMintId = ONFTStorage.oNFTStorageLayout().startMintId;
        maxMintId = ONFTStorage.oNFTStorageLayout().endMintId;

        console.log('nextMintId', nextMintId);
        console.log('maxMintId', maxMintId);

        uint256 dirtBikeHash = getHash();

        uint newId = nextMintId;
        nextMintId++;

        require(nextMintId <= maxMintId, 'UniversalONFT721: max mint limit reached');

        // Store psuedo-randomHash as DirtBike VIN
        DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[newId] = dirtBikeHash;

        _safeMint(_tokenOwner, newId);
    }
}
