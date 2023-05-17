// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../utils/Strings.sol';
import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import {DirtBikesStorage} from './DirtBikesStorage.sol';

import 'hardhat/console.sol';

contract RenderFacet is ERC721Internal {
    using Strings for uint256;

    // Events
    // event DirtBikeCreated(uint indexed tokenId);

    // struct DirtBike {
    //     uint x; // x coordinates of the top left corner
    //     uint y; // y coordinates of the top left corner
    //     uint width;
    //     uint height;
    //     string fillDirtBikePartsColors;
    //     string fillForkColors;
    //     string fillSwingArmColors;
    //     string fillWheelColors;
    //     uint randomSeed;
    // }

    // // Return a random background color
    // function backgroundColors(uint index) internal pure returns (string memory) {
    //     string[7] memory bgColors = ['#66ccf3', '#64A864', '#b08f26', '#f06eaa', '#d3d6d8', '#a27ca2', '#aaa9ad'];
    //     return bgColors[index];
    // }

    // // Return a random part color
    // function dirtBikePartsColors(uint index) internal pure returns (string memory) {
    //     string[7] memory bColors = ['#000000', '#00abec', '#3c643c', '#ffa500', '#7b457b', '#ffffff', '#d33a00'];
    //     return bColors[index];
    // }

    // function forkColors(uint index) internal pure returns (string memory) {
    //     string[2] memory fColors = ['#000000', '#8c8c8c'];
    //     return fColors[index];
    // }

    // function swingArmColors(uint index) internal pure returns (string memory) {
    //     string[2] memory saColors = ['#000000', '#8c8c8c'];
    //     return saColors[index];
    // }

    // function wheelColors(uint index) internal pure returns (string memory) {
    //     string[2] memory wColors = ['#000000', '#6f4e37'];
    //     return wColors[index];
    // }

    // Create an instance of a Ball
    // function createDirtbikeStruct(
    //     uint x,
    //     uint y,
    //     uint width,
    //     uint height,
    //     uint randomSeed
    // ) internal pure returns (DirtBike memory) {
    //     return
    //         DirtBike({
    //             x: x,
    //             y: y,
    //             width: width,
    //             height: height,
    //             fillDirtBikePartsColors: dirtBikePartsColors(randomSeed % 7), // Choose random color from array
    //             fillForkColors: forkColors(randomSeed % 2),
    //             fillSwingArmColors: swingArmColors(randomSeed % 2),
    //             fillWheelColors: wheelColors(randomSeed % 2),
    //             randomSeed: randomSeed
    //         });
    // }

    // Start from the end

    // // SVG code for a single ball
    // function dirtbikeSvg(DirtBike memory dirtbike) public pure returns (string memory) {
    //     return
    //         string(
    //             abi.encodePacked(
    //                 // <!-- rear wheel -->

    //                 '<rect x="100" y="1000" width="100" height="200" fill="black" />',
    //                 '<rect x="200" y="1200" width="200" height="100" fill="black" />',
    //                 '<rect x="200" y="900" width="200" height="100" fill="black" />',
    //                 '<rect x="400" y="1000" width="100" height="200" fill="black" />'
    //             )
    //         );
    // }

    // // SVG code for a single line
    // function generateDirtBikeSvg(uint randomSeed) public view returns (string memory) {
    //     // Dirt Bike SVG
    //     string memory dirtBikeSvg = '';

    //     DirtBike memory dirtBike = createDirtbikeStruct(500, 500, 1600, 1600, randomSeed);

    //     dirtBikeSvg = string.concat(dirtBikeSvg, dirtbikeSvg(dirtBike));
    // }

    // function generateFinalDirtBikeSvg(uint randomSeed) public view returns (string memory) {
    //     bytes memory backgroundCode = abi.encodePacked(
    //         '<rect width="1600" height="1600" fill="',
    //         backgroundColors(randomSeed % 7),
    //         generateDirtBikeSvg(randomSeed),
    //         '" />'
    //     );

    //     // SVG opening and closing tags, background color + 3 lines generated
    //     string memory finalSvg = string(
    //         abi.encodePacked(
    //             '<svg viewBox="0 0 1600 1600" xmlns="http://www.w3.org/2000/svg">',
    //             backgroundCode,
    //             generateDirtBikeSvg(randomSeed),
    //             '</svg>'
    //         )
    //     );

    //     console.log('Final Svg: ', string(finalSvg));
    //     return finalSvg;
    // }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        // string memory baseURI = _baseURI();
        // return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';

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

    // /**
    //  * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    //  * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
    //  * by default, can be overridden in child contracts.
    //  */
    // function _baseURI() internal view virtual returns (string memory) {
    //     return '';
    // }
}
