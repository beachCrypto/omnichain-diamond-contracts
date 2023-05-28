// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';
import {ERC721AUpgradeableInternal} from '../ERC721-Contracts/ERC721AUpgradeableInternal.sol';
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

        // // TODO Update to ERC721A. Store map each hash to tokenId
        // require(
        //     ONFTStorage.oNFTStorageLayout().nextMintId <= ONFTStorage.oNFTStorageLayout().maxMintId,
        //     'UniversalONFT721: max mint limit reached'
        // );

        // uint newId = ONFTStorage.oNFTStorageLayout().nextMintId;
        // ONFTStorage.oNFTStorageLayout().nextMintId++;

        // // Store psuedo-randomHash as DirtBike VIN
        // DirtBikesStorage.dirtBikeslayout().tokenToHash[newId] = dirtBikeHash;

        // // ERC721A mint
        // _safeMint(msg.sender, _amount, '');
        _safeMint(msg.sender, _amount, '');
    }
}
