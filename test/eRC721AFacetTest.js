/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployDiamond} = require('../scripts/deploy.js');

const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

// Layer Zero

const {ethers} = require('hardhat');

let offsetted;

describe('ERC721', async () => {
    let diamondAddress;
    let mintFacet;
    let eRC721;
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

        eRC721 = await ethers.getContractAt('ERC721Internal', diamondAddress);

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
        expect(await eRC721.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet.connect(ownerAddress).mint(1);

        expect(await eRC721.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await eRC721.transferFrom(ownerAddress.address, warlock.address, 0);

        expect(await eRC721.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        expect(await eRC721.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721.connect(warlock.address).ownerOf(0)).to.equal(warlock.address);

        await eRC721.connect(warlock).approve(eRC721.address, 0);
    });

    it('Sender can transfer an NFT', async () => {
        expect(await eRC721.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet.connect(ownerAddress).mint(1);

        expect(await eRC721.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await eRC721.transferFrom(ownerAddress.address, warlock.address, 0);

        expect(await eRC721.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        expect(await eRC721.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721.connect(warlock.address).ownerOf(0)).to.equal(warlock.address);
    });

    it('Sender can approve an NFT', async () => {
        expect(await eRC721.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet.connect(ownerAddress).mint(1);

        expect(await eRC721.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await eRC721.transferFrom(ownerAddress.address, warlock.address, 0);

        expect(await eRC721.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        expect(await eRC721.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721.connect(warlock.address).ownerOf(0)).to.equal(warlock.address);

        await eRC721.connect(warlock).approve(eRC721.address, 0);
    });
});
