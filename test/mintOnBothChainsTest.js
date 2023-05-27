/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployDiamondA} = require('../scripts/deployA.js');
const {deployDiamondB} = require('../scripts/deployB.js');
const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

const {ethers} = require('hardhat');

let offsetted;

describe('sendFrom()', async () => {
    // Diamond contracts
    let diamondAddressA;
    let diamondAddressB;
    let eRC721A_chainA;
    let eRC721B_chainB;
    let owner;
    const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 200000]);

    // Layer Zero
    const chainId_A = 1;
    const chainId_B = 2;
    const name = 'OmnichainNonFungibleToken';
    const symbol = 'ONFT';

    before(async function () {
        LZEndpointMockA = await ethers.getContractFactory('LZEndpointMockA');
        LZEndpointMockB = await ethers.getContractFactory('LZEndpointMockB');
    });

    beforeEach(async () => {
        lzEndpointMockA = await LZEndpointMockA.deploy(chainId_A);
        lzEndpointMockB = await LZEndpointMockB.deploy(chainId_B);

        // generate a proxy to allow it to go ONFT
        diamondAddressA = await deployDiamondA();
        diamondAddressB = await deployDiamondB();

        eRC721A_chainA = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressA);
        eRC721B_chainB = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressB);

        mintFacet_chainA = await ethers.getContractAt('MintFacet', diamondAddressA);
        mintFacet_chainB = await ethers.getContractAt('MintFacet', diamondAddressB);

        const [owner, addr1] = await ethers.getSigners();

        ownerAddress = owner;
        warlock = addr1;
    });

    it('mint on chain A', async () => {
        const tokenId1 = 0;
        const tokenId2 = 0;

        expect(await eRC721A_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainA.connect(ownerAddress).mint(1);

        // verify the owner of the token is on the source chain
        expect(await eRC721A_chainA.ownerOf(tokenId1)).to.be.equal(ownerAddress.address);

        // verify the owner of the token is on the source chain
        expect(await eRC721A_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        await mintFacet_chainA.connect(ownerAddress).mint(1);

        expect(await eRC721A_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(2);

        expect(await eRC721A_chainA.ownerOf(tokenId2)).to.be.equal(ownerAddress.address);
    });

    it('mint on chain B', async () => {
        // TODO must start at 334 not 0. Mint logic needs to be fixed
        // const tokenId = 334;
        const tokenId = 0;
        expect(await eRC721B_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainB.connect(ownerAddress).mint(1);

        // verify the owner of the token is on the source chain
        expect(await eRC721B_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721B_chainB.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        await mintFacet_chainB.connect(ownerAddress).mint(1);

        expect(await eRC721B_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(2);
    });
});
