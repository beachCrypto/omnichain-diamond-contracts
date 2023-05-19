// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Base64.sol';
import '../utils/Strings.sol';

import {DirtBikesStorage} from './DirtBikesStorage.sol';
import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';

import 'hardhat/console.sol';

contract RenderFacet is ERC721Internal {
    using Strings for uint256;

    struct DirtBike {
        string fillDirtBikePartsColors;
        string engine;
        string fillForkColors;
        string frontFenderColor;
        string gasTankColor;
        string handlebar;
        string swingArmColors;
        string rearWheelColor;
        string rearFenderColor;
        string frontWheelColor;
    }

     // Return a random background color
    function backgroundColors(uint index) internal pure returns (string memory) {
        string[10] memory bgColors = ['#66ccf3', '#64A864', '#b08f26', '#f06eaa', '#d3d6d8', '#a27ca2', '#aaa9ad', '#247881', '#00FFC6', '#9D5353'];
        return bgColors[index];
    }

    // Return a random part color
    function dirtBikePartsColors(uint index) internal pure returns (string memory) {
        string[10] memory bColors = ['#2C3333', '#00abec', '#3c643c', '#EA5C2B', '#7b457b', '#F6F1F1', '#d33a00', '#78B7BB', '#808B97', '#025464'];
        return bColors[index];
    }

    function forkColors(uint index) internal pure returns (string memory) {
        string[4] memory fColors = ['#2C3333','#E57C23', '#8c8c8c','#BE5A83'];
        return fColors[index];
    }

    function swingArmColors(uint index) internal pure returns (string memory) {
        string[4] memory saColors = ['#2C3333', '#8c8c8c', '#E57C23','#BE5A83'];
        return saColors[index];
    }

    function wheelColors(uint index) internal pure returns (string memory) {
        string[2] memory wColors = ['#4D4D4D', '#6f4e37'];
        return wColors[index];
    }

     // Each part needs it's own variable
    function createDirtbikeStruct(uint256[] memory randomSeed) internal pure returns (DirtBike memory) {
        return
            DirtBike({
                engine: dirtBikePartsColors(randomSeed[0]), // Choose random color from array
                fillDirtBikePartsColors: dirtBikePartsColors(randomSeed[1]),
                fillForkColors: forkColors(randomSeed[2] % 4),
                frontFenderColor: dirtBikePartsColors(randomSeed[3]),
                gasTankColor: dirtBikePartsColors(randomSeed[4]),
                handlebar: dirtBikePartsColors(randomSeed[5]),
                swingArmColors: swingArmColors(randomSeed[6] % 4),
                rearWheelColor: wheelColors(randomSeed[7] % 2),
                rearFenderColor: dirtBikePartsColors(randomSeed[8]),
                frontWheelColor: wheelColors(randomSeed[9] % 2)
            });
    }

    function rearWheelSvg(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    // <!-- rear wheel -->
                    '<rect x="100" y="1000" width="100" height="200" fill="',
                    dirtbike.rearWheelColor,
                    '" />',
                    '<rect x="200" y="1200" width="200" height="100" fill="',
                    dirtbike.rearWheelColor,
                    '" />',
                    '<rect x="200" y="900" width="200" height="100" fill="',
                    dirtbike.rearWheelColor,
                    '" />',
                    '<rect x="400" y="1000" width="100" height="200" fill="',
                    dirtbike.rearWheelColor,
                    '" />'
                )
            );
    }

      function frontWheelSvg(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    // <!-- front wheel -->
                    '<rect x="1000" y="1000" width="100" height="200" fill="',
                    dirtbike.frontWheelColor,
                    '" />',

                    '<rect x="1100" y="1200" width="200" height="100" fill="',
                    dirtbike.frontWheelColor,
                    '" />',

                    '<rect x="1100" y="900" width="200" height="100" fill="',
                    dirtbike.frontWheelColor,
                    '" />',

                    '<rect x="1300" y="1000" width="100" height="200" fill="',
                    dirtbike.frontWheelColor,
                    '" />'
                )
            );
    }

    function driveTrainSvg(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(

                    // <!-- swing arm -->
                    '<rect x="300" y="1000" width="400" height="100" fill="',
                    dirtbike.swingArmColors,
                    '" />'

                    '<rect x="500" y="900" width="100" height="200" fill="',
                    dirtbike.swingArmColors,
                    '" />'

                    // <!-- engine -->
                    '<rect x="500" y="800" width="400" height="100" fill="',
                    dirtbike.engine,
                    '" />'
                    '<rect x="600" y="900" width="300" height="100" fill="',
                    dirtbike.engine,
                    '" />'
                    '<rect x="600" y="800" width="100" height="200" fill="',
                    dirtbike.engine,
                    '" />'
                    '<rect x="700" y="800" width="100" height="200" fill="',
                    dirtbike.engine,
                    '" />'
                    '<rect x="800" y="800" width="100" height="200" fill="',
                    dirtbike.engine,
                    '" />'
                )
            );
    }

    function body(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(

                    //  <!-- rear fender -->
                    '<rect x="200" y="600" width="300" height="100" fill="',
                    dirtbike.rearFenderColor,
                    '" />'
                    '<rect x="400" y="700" width="200" height="100" fill="',
                    dirtbike.rearFenderColor,
                    '" />'
                    '<rect x="400" y="600" width="100" height="200" fill="',
                    dirtbike.rearFenderColor,
                    '" />'
                    // <!-- front fender -->
                    '<rect x="900" y="700" width="300" height="100" fill="',
                    dirtbike.frontFenderColor,
                    '" />'
                    // <!-- gas tank -->
                    '<rect x="700" y="700" width="200" height="100" fill="',
                    dirtbike.gasTankColor,
                    '" />'
                )
            );
    }

     function frontEnd(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    // <!-- fork -->
                    '<rect x="900" y="800" width="100" height="100" fill="',
                    dirtbike.fillForkColors,
                    '" />'
                    '<rect x="1000" y="900" width="100" height="100" fill="',
                    dirtbike.fillForkColors,
                    '" />'
                    '<rect x="1100" y="1000" width="100" height="100" fill="',
                    dirtbike.fillForkColors,
                    '" />'

                    // <!-- handlebar -->
                    '<rect x="900" y="500" width="100" height="200" fill="',
                    dirtbike.handlebar,
                    '" />'
                    '<rect x="800" y="500" width="200" height="100" fill="',
                    dirtbike.handlebar,
                    '" />'

                )
            );
    }

     // SVG code for a single line
    function generateDirtBikeSvg(uint256[] memory randomSeed) public pure returns (string memory) {
        // Dirt Bike SVG
        string memory dirtBikeSvg = '';

        DirtBike memory dirtBike = createDirtbikeStruct(randomSeed);

        return
            dirtBikeSvg = string.concat(
                dirtBikeSvg,
                rearWheelSvg(dirtBike),
                frontWheelSvg(dirtBike),
                driveTrainSvg(dirtBike),
                body(dirtBike),
                frontEnd(dirtBike)
            );
    }

    function generateFinalDirtBikeSvg(uint256[] memory randomSeed) public pure returns (string memory) {
        bytes memory backgroundCode = abi.encodePacked(
            '<rect width="1600" height="1600" fill="',
            backgroundColors(randomSeed[0] % 9),
            '" />'
        );

        // SVG opening and closing tags, background color + 3 lines generated
        string memory finalSvg = string(
            abi.encodePacked(
                '<svg viewBox="0 0 1600 1600" xmlns="http://www.w3.org/2000/svg">',
                backgroundCode,
                generateDirtBikeSvg(randomSeed),
                '</svg>'
            )
        );

        return finalSvg;
    }

    function generateStats(uint256 tokenId) public view returns (uint256[] memory) {
        // generate psuedo-randomHash
        // uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee)));

        uint256 randomHash = DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[tokenId];

        // build an array of predefined length
        uint256[] memory stats = new uint256[](10);

        // iterate over the number of stats we want a random number for
        for (uint256 i; i < 10; i++) {
            // use random number to get number between 0 and maxStatValue
            stats[i] = randomHash % 10;
            // bit shift randomHash to the right 8 bits - can be fewer
            randomHash >>= 8;
        }

        return stats;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        uint256[] memory randomSeed = generateStats(tokenId);

        string memory onChainDirtbike = generateFinalDirtBikeSvg(randomSeed);

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Dirt Bikes #',
                                uint2str(tokenId),
                                '", "description": "Dirt Bikes Omnichain Diamond NFTs", "attributes": "", "image":"data:image/svg+xml;base64,',
                                Base64.encode(bytes(onChainDirtbike)),
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
