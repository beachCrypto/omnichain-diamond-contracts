// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Base64.sol';
import '../utils/Strings.sol';

import {DirtBikesStorage} from './DirtBikesStorage.sol';
import {ERC721Internal} from '../ERC721-Contracts/ERC721Internal.sol';

import 'hardhat/console.sol';

contract RenderFacet is ERC721Internal {
    using Strings for uint256;

    struct DirtBike {
        string background;
        string engine;
        string forks;
        string frontFender;
        string gasTank;
        string handlebars;
        string swingArm;
        string rearWheel;
        string rearFender;
        string frontWheel;
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

    function swingArm(uint index) internal pure returns (string memory) {
        string[4] memory saColors = ['#2C3333', '#8c8c8c', '#E57C23','#BE5A83'];
        return saColors[index];
    }

    function wheelColors(uint index) internal pure returns (string memory) {
        string[2] memory wColors = ['#4D4D4D', '#6f4e37'];
        return wColors[index];
    }

     // Each part needs it's own variable
    function createDirtBike(uint256[] memory randomSeed) internal pure returns (DirtBike memory) {
        return
            DirtBike({
                background: backgroundColors(randomSeed[0] % 9),
                engine: dirtBikePartsColors(randomSeed[0]), // Choose random color from array
                forks: forkColors(randomSeed[1] % 4),
                frontFender: dirtBikePartsColors(randomSeed[2]),
                gasTank: dirtBikePartsColors(randomSeed[3]),
                handlebars: dirtBikePartsColors(randomSeed[4]),
                swingArm: swingArm(randomSeed[5] % 4),
                rearWheel: wheelColors(randomSeed[6] % 2),
                rearFender: dirtBikePartsColors(randomSeed[7]),
                frontWheel: wheelColors(randomSeed[8] % 2)
            });
    }

    function background(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            (string(
                abi.encodePacked(
                    // <!-- background -->
                    '<rect width="1600" height="1600" fill="',
                    dirtbike.background,
                    '" />'
                )
            ));
    }

    function rearWheelSvg(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    // <!-- rear wheel -->
                    '<rect x="100" y="1000" width="100" height="200" fill="',
                    dirtbike.rearWheel,
                    '" />',
                    '<rect x="200" y="1200" width="200" height="100" fill="',
                    dirtbike.rearWheel,
                    '" />',
                    '<rect x="200" y="900" width="200" height="100" fill="',
                    dirtbike.rearWheel,
                    '" />',
                    '<rect x="400" y="1000" width="100" height="200" fill="',
                    dirtbike.rearWheel,
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
                    dirtbike.frontWheel,
                    '" />',

                    '<rect x="1100" y="1200" width="200" height="100" fill="',
                    dirtbike.frontWheel,
                    '" />',

                    '<rect x="1100" y="900" width="200" height="100" fill="',
                    dirtbike.frontWheel,
                    '" />',

                    '<rect x="1300" y="1000" width="100" height="200" fill="',
                    dirtbike.frontWheel,
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
                    dirtbike.swingArm,
                    '" />'

                    '<rect x="500" y="900" width="100" height="200" fill="',
                    dirtbike.swingArm,
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
                    dirtbike.rearFender,
                    '" />'
                    '<rect x="400" y="700" width="200" height="100" fill="',
                    dirtbike.rearFender,
                    '" />'
                    '<rect x="400" y="600" width="100" height="200" fill="',
                    dirtbike.rearFender,
                    '" />'
                    // <!-- front fender -->
                    '<rect x="900" y="700" width="300" height="100" fill="',
                    dirtbike.frontFender,
                    '" />'
                    // <!-- gas tank -->
                    '<rect x="700" y="700" width="200" height="100" fill="',
                    dirtbike.gasTank,
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
                    dirtbike.forks,
                    '" />'
                    '<rect x="1000" y="900" width="100" height="100" fill="',
                    dirtbike.forks,
                    '" />'
                    '<rect x="1100" y="1000" width="100" height="100" fill="',
                    dirtbike.forks,
                    '" />'

                    // <!-- handlebars -->
                    '<rect x="900" y="500" width="100" height="200" fill="',
                    dirtbike.handlebars,
                    '" />'
                    '<rect x="800" y="500" width="200" height="100" fill="',
                    dirtbike.handlebars,
                    '" />'

                )
            );
    }

    function generateFinalDirtBikeSvg(DirtBike memory dirtBike) public view returns (string memory) {

      string memory dirtBikeSvg = '';

      dirtBikeSvg = string.concat(
                dirtBikeSvg,
                background(dirtBike),
                rearWheelSvg(dirtBike),
                frontWheelSvg(dirtBike),
                driveTrainSvg(dirtBike),
                body(dirtBike),
                frontEnd(dirtBike)
            );




        // SVG opening and closing tags, background color + 3 lines generated
        string memory finalSvg = string(
            abi.encodePacked(
                '<svg viewBox="0 0 1600 1600" xmlns="http://www.w3.org/2000/svg">',
                dirtBikeSvg,
                '</svg>'
            )
        );

        console.log("finalSvg: ", finalSvg);

        return dirtBikeSvg;
    }

    // Cool Cats Solidity — Random Numbers - https://medium.com/coinmonks/solidity-random-numbers-f54e1272c7dd
    function generateStats(uint256 tokenId) public view returns (uint256[] memory) {
        // Pull Dirt Bike Vin from storage
        uint256 randomHash = DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[tokenId];

        // build an array of predefined length
        uint256[] memory vin = new uint256[](10);

        // iterate over the number of stats we want a random number for
        for (uint256 i; i < 10; i++) {
            // use random number to get number between 0 and maxStatValue
            vin[i] = randomHash % 10;
            // bit shift randomHash to the right 8 bits - can be fewer
            randomHash >>= 8;
        }

        return vin;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        uint256[] memory randomSeed = generateStats(tokenId);

        // Here is where the dirt bike should be built
        DirtBike memory dirtBike = createDirtBike(randomSeed);

        string memory onChainDirtbike = generateFinalDirtBikeSvg(dirtBike);

        // TODO this calculation should only be run in one place
        string memory fork = forkColors(randomSeed[1] % 4);


        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Dirt Bikes #',
                                uint2str(tokenId),
                                '", "description": "Dirt Bikes Omnichain Diamond NFTs",',
                                '"attributes": [',
                                  '{ "trait_type": "Base", "value": "',fork,'" },',
                                '],',
                                '"image":"data:image/svg+xml;base64,',
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
