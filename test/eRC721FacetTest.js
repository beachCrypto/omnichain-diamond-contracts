/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployERC721DiamondB} = require('../scripts/deployERC721_b.js');
const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

const {ethers} = require('hardhat');

let offsetted;

describe('sendFrom()', async () => {
    // Diamond contracts
    let diamondAddressA;
    let diamondERC721AddressB;
    let eRC721_chainB;
    let owner;
    const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 200000]);

    // Layer Zero
    const chainId_A = 1;
    const chainId_B = 2;
    const name = 'ERC721';
    const symbol = 'ERC721';

    before(async function () {});

    beforeEach(async () => {
        // generate a proxy to allow it to go ONFT
        diamondERC721AddressB = await deployERC721DiamondB();

        eRC721_chainB = await ethers.getContractAt('ERC721', diamondERC721AddressB);

        mintFacetERC721_chainB = await ethers.getContractAt('MintFacetERC721', diamondERC721AddressB);

        NonblockingLzAppUpgradeableB = await ethers.getContractAt('NonblockingLzAppUpgradeable', diamondERC721AddressB);

        const [owner, addr1] = await ethers.getSigners();

        ownerAddress = owner;
        warlock = addr1;
    });

    it('mint on ERC721 chain B', async () => {
        const tokenId = 1;
        expect(await eRC721_chainB.connect(ownerAddress).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacetERC721_chainB.mint(ownerAddress.address, tokenId);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);
    });

    it('Sender can transfer an NFT', async () => {
        const tokenId = 1;
        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacetERC721_chainB.mint(ownerAddress.address, tokenId);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await eRC721_chainB.transferFrom(ownerAddress.address, warlock.address, tokenId);

        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        expect(await eRC721_chainB.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721_chainB.connect(warlock.address).ownerOf(tokenId)).to.equal(warlock.address);
    });

    it('Sender can approve an NFT', async () => {
        const tokenId = 1;
        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacetERC721_chainB.mint(ownerAddress.address, tokenId);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainB.ownerOf(1)).to.be.equal(ownerAddress.address);

        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await eRC721_chainB.transferFrom(ownerAddress.address, warlock.address, tokenId);

        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        expect(await eRC721_chainB.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721_chainB.connect(warlock.address).ownerOf(tokenId)).to.equal(warlock.address);

        await eRC721_chainB.connect(warlock).approve(eRC721_chainB.address, tokenId);
    });
});
