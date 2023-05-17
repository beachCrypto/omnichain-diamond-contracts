// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../utils/Strings.sol';
import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import {DirtBikesStorage} from './DirtBikesStorage.sol';

import 'hardhat/console.sol';

contract RenderFacet is ERC721Internal {
    using Strings for uint256;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Balls of Art #',
                                uint2str(tokenId),
                                '", "description": "Balls of Art are an assortment of 111 fully on-chain, randomly generated, happy art balls", "attributes": "", "image":"data:image/svg+xml;base64,',
                                Base64.encode(bytes(DirtBikesStorage.dirtBikeslayout().tokenIdToSvg[tokenId])),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    // From: https://stackoverflow.com/a/65707309/11969592
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
