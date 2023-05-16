/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployDiamondA} = require('../scripts/deployA.js');
const {deployDiamondB} = require('../scripts/deployB.js');
const {offsettedIndex} = require('./helpers/helpers.js');
const {assert, expect} = require('chai');

const {ethers} = require('hardhat');

let offsetted;

describe('ERC721', async () => {
    // Diamond contracts
    let diamondAddressA;
    let diamondAddressB;
    let eRC721_chainA;
    let owner;
    const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 200000]);

    // Layer Zero
    const chainId_A = 1;
    const chainId_B = 2;
    const name = 'OmnichainNonFungibleToken';
    const symbol = 'ONFT';

    before(async function () {
        LZEndpointMockA = await ethers.getContractFactory('LZEndpointMockA');
    });

    beforeEach(async () => {
        lzEndpointMockA = await LZEndpointMockA.deploy(chainId_A);

        diamondAddressA = await deployDiamondA();

        mintFacet_chainA = await ethers.getContractAt('MintFacet', diamondAddressA);

        eRC721_chainA = await ethers.getContractAt('ERC721', diamondAddressA);

        startTokenId = 0;

        offsetted = (...arr) => offsettedIndex(startTokenId, arr);

        const [owner, addr1] = await ethers.getSigners();

        ownerAddress = owner;
        warlock = addr1;

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
        const tokenId = 1;
        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainA.connect(ownerAddress).mint(ownerAddress.address, tokenId);

        expect(await eRC721_chainA.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await eRC721_chainA.transferFrom(ownerAddress.address, warlock.address, tokenId);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        expect(await eRC721_chainA.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721_chainA.connect(warlock.address).ownerOf(tokenId)).to.equal(warlock.address);

        await eRC721_chainA.connect(warlock).approve(eRC721_chainA.address, tokenId);
    });

    it('Sender can transfer an NFT', async () => {
        const tokenId = 12;
        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainA.connect(ownerAddress).mint(ownerAddress.address, tokenId);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await eRC721_chainA.transferFrom(ownerAddress.address, warlock.address, tokenId);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        expect(await eRC721_chainA.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721_chainA.connect(warlock.address).ownerOf(tokenId)).to.equal(warlock.address);
    });

    it('Sender can approve an NFT', async () => {
        const tokenId = 123;
        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainA.connect(ownerAddress).mint(ownerAddress.address, tokenId);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await eRC721_chainA.transferFrom(ownerAddress.address, warlock.address, tokenId);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        expect(await eRC721_chainA.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721_chainA.connect(warlock.address).ownerOf(tokenId)).to.equal(warlock.address);

        await eRC721_chainA.connect(warlock).approve(eRC721_chainA.address, tokenId);
    });
});
