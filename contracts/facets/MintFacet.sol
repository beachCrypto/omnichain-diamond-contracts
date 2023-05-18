// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';
import {DirtBikesStorage} from './DirtBikesStorage.sol';

import 'hardhat/console.sol';

contract MintFacet is ERC721Internal {
    event DirtBikeCreated(uint indexed tokenId);

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
        uint randomSeed;
    }

    // Return a random background color
    function backgroundColors(uint index) internal pure returns (string memory) {
        string[7] memory bgColors = ['#66ccf3', '#64A864', '#b08f26', '#f06eaa', '#d3d6d8', '#a27ca2', '#aaa9ad'];
        return bgColors[index];
    }

     // Return a random part color
    function engine(uint index) internal pure returns (string memory) {
        string[10] memory bColors = ['#000000', '#00abec', '#3c643c', '#ffa500', '#7b457b', '#ffffff', '#d33a00', '#78B7BB', '#808B97', '#025464'];
        return bColors[index];
    }

    // Return a random part color
    function dirtBikePartsColors(uint index) internal pure returns (string memory) {
        string[10] memory bColors = ['#000000', '#00abec', '#3c643c', '#ffa500', '#7b457b', '#ffffff', '#d33a00', '#78B7BB', '#808B97', '#025464'];
        return bColors[index];
    }

    function forkColors(uint index) internal pure returns (string memory) {
        string[2] memory fColors = ['#000000', '#8c8c8c'];
        return fColors[index];
    }

    function swingArmColors(uint index) internal pure returns (string memory) {
        string[2] memory saColors = ['#000000', '#8c8c8c'];
        return saColors[index];
    }

    function wheelColors(uint index) internal pure returns (string memory) {
        string[2] memory wColors = ['#000000', '#6f4e37'];
        return wColors[index];
    }

    // Each part needs it's own variable
    function createDirtbikeStruct(uint randomSeed) internal pure returns (DirtBike memory) {
        return
            DirtBike({
                engine: engine(randomSeed % 9), // Choose random color from array
                fillDirtBikePartsColors: dirtBikePartsColors(randomSeed % 10 >> 1),
                fillForkColors: forkColors(randomSeed % 2),
                frontFenderColor: dirtBikePartsColors(randomSeed % 10 >> 2),
                gasTankColor: dirtBikePartsColors(randomSeed % 10 >> 3),
                handlebar: dirtBikePartsColors(randomSeed % 10 >> 4),
                swingArmColors: swingArmColors(randomSeed % 2),
                rearWheelColor: wheelColors(randomSeed % 2),
                rearFenderColor: dirtBikePartsColors(randomSeed % 10 >> 5),
                frontWheelColor: wheelColors(randomSeed % 2 >> 1),
                randomSeed: randomSeed
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
    function generateDirtBikeSvg(uint randomSeed) public view returns (string memory) {
        // Dirt Bike SVG
        string memory dirtBikeSvg = '';

        DirtBike memory dirtBike = createDirtbikeStruct(randomSeed);

        return dirtBikeSvg = string.concat(dirtBikeSvg, rearWheelSvg(dirtBike), frontWheelSvg(dirtBike), driveTrainSvg(dirtBike), body(dirtBike), frontEnd(dirtBike));
    }

    function generateFinalDirtBikeSvg(uint randomSeed) public view returns (string memory) {
        bytes memory backgroundCode = abi.encodePacked(
            '<rect width="1600" height="1600" fill="',
            backgroundColors(randomSeed % 9),
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

        console.log('Final Svg: ', string(finalSvg));
        return finalSvg;
    }

    function mint(address _tokenOwner, uint _tokenId) external payable {
        // TODO this randomSeed is not sufficient
        uint randomSeed = uint(keccak256(abi.encodePacked(block.basefee, block.timestamp)));

        uint randomSeed1 = uint(keccak256(abi.encodePacked(block.basefee, block.timestamp)));

        console.log("randomSeed", randomSeed, "randomSeed1", randomSeed1);

        DirtBikesStorage.dirtBikeslayout().tokenIdToSvg[_tokenId] = generateFinalDirtBikeSvg(randomSeed);

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
