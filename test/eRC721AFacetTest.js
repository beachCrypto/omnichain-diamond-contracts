/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployDiamond} = require('../scripts/deploy.js');

const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

// Layer Zero

const {ethers} = require('hardhat');

let offsetted;

describe('Transfer', async () => {
    let diamondAddress;
    let mintFacet;
    let eRC721AUpgradeable;
    let owner;

    // Layer Zero

    const chainId_A = 1;
    const chainId_B = 2;
    const name = 'OmnichainNonFungibleToken';
    const symbol = 'ONFT';

    before(async function () {
        LZEndpointMock = await ethers.getContractFactory('LZEndpointMock');
    });

    beforeEach(async () => {
        lzEndpointMockA = await LZEndpointMock.deploy(chainId_A);
        lzEndpointMockB = await LZEndpointMock.deploy(chainId_B);

        diamondAddress = await deployDiamond();

        mintFacet = await ethers.getContractAt('MintFacet', diamondAddress);

        eRC721AUpgradeable = await ethers.getContractAt('ERC721AUpgradeable', diamondAddress);

        startTokenId = 0;

        offsetted = (...arr) => offsettedIndex(startTokenId, arr);

        const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

        warlock = addr1;
        ownerAddress = owner;

        ownerAddress.expected = {
            mintCount: 1,
            tokens: offsetted(0),
        };

        warlock.expected = {
            mintCount: 2,
            tokens: [offsetted(1, 2)],
        };
    });

    it('Sender can mint an NFT', async () => {
        expect(await eRC721AUpgradeable.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet.connect(ownerAddress).mint(1);

        expect(await eRC721AUpgradeable.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await eRC721AUpgradeable.transferFrom(ownerAddress.address, warlock.address, 0);

        expect(await eRC721AUpgradeable.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        expect(await eRC721AUpgradeable.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);
    });
});
