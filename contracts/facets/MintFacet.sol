// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';
import {ERC721AUpgradeableInternal} from '../ERC721A-Contracts/ERC721AUpgradeableInternal.sol';
import {ONFTStorage} from '../layerZeroLibraries/ONFTStorage.sol';

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
        _safeMint(msg.sender, _amount, '');
    }
}
