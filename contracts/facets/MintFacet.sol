// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';
import {ERC721AUpgradeableInternal} from '../ERC721-Contracts/ERC721AUpgradeableInternal.sol';
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';

import 'hardhat/console.sol';

contract MintFacet is ERC721AUpgradeableInternal {
    uint public nextMintId;
    uint public maxMintId;

    event DirtBikeCreated(uint indexed tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function getHash() public view returns (uint256) {
        // generate psuedo-randomHash
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee)));

        return randomHash;
    }

    function mint() external payable {
        maxMintId = LayerZeroEndpointStorage.layerZeroEndpointSlot().maxTokenId;

        uint256 dirtBikeHash = getHash();

        uint tokenId = _nextTokenId();

        require(msg.sender == tx.origin, 'Contract cannot mint');

        require(_nextTokenId() <= maxMintId, 'UniversalONFT721: max mint limit reached');

        // Store psuedo-randomHash as DirtBike VIN
        DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[tokenId] = dirtBikeHash;

        if (tokenId != 0) emit BatchMetadataUpdate(0, tokenId - 1);

        _mint(msg.sender, 1);
    }
}
