// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DirtBikesStorage} from './DirtBikesStorage.sol';
import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';

import 'hardhat/console.sol';

contract MintFacet is ERC721Internal {
    event DirtBikeCreated(uint indexed tokenId);

    uint256 maxStatValue = 100;

    function getHash() public view returns (uint256) {
        // generate psuedo-randomHash
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee)));

        return randomHash;
    }

    function mint(address _tokenOwner, uint _tokenId) external payable {
        uint256 dirtBikeDNA = getHash();

        DirtBikesStorage.dirtBikeslayout().dirtbikeVIN[_tokenId] = dirtBikeDNA;

        // DirtBikesStorage.dirtBikeslayout().tokenIdToSvg[_tokenId] = generateFinalDirtBikeSvg(randomSeed);

        _safeMint(_tokenOwner, _tokenId);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return '0';
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
