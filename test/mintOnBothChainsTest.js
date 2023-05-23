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
        LZEndpointMockB = await ethers.getContractFactory('LZEndpointMockB');
    });

    beforeEach(async () => {
        lzEndpointMockA = await LZEndpointMockA.deploy(chainId_A);
        lzEndpointMockB = await LZEndpointMockB.deploy(chainId_B);

        // generate a proxy to allow it to go ONFT
        diamondAddressA = await deployDiamondA();
        diamondAddressB = await deployDiamondB();

        eRC721_chainA = await ethers.getContractAt('ERC721', diamondAddressA);
        eRC721_chainB = await ethers.getContractAt('ERC721', diamondAddressB);

        mintFacet_chainA = await ethers.getContractAt('MintFacet', diamondAddressA);
        mintFacet_chainB = await ethers.getContractAt('MintFacet', diamondAddressB);

        NonblockingLzAppUpgradeableA = await ethers.getContractAt('NonblockingLzAppUpgradeable', diamondAddressA);
        NonblockingLzAppUpgradeableB = await ethers.getContractAt('NonblockingLzAppUpgradeable', diamondAddressB);

        // wire the lz endpoints to guide msgs back and forth
        lzEndpointMockA.setDestLzEndpoint(diamondAddressB.address, lzEndpointMockB.address);
        lzEndpointMockB.setDestLzEndpoint(diamondAddressA.address, lzEndpointMockA.address);

        // set each contracts source address so it can send to each other
        await NonblockingLzAppUpgradeableA.setTrustedRemote(
            chainId_B,
            ethers.utils.solidityPack(['address', 'address'], [diamondAddressB, diamondAddressA])
        );

        await NonblockingLzAppUpgradeableB.setTrustedRemote(
            chainId_A,
            ethers.utils.solidityPack(['address', 'address'], [diamondAddressA, diamondAddressB])
        );

        const [owner, addr1] = await ethers.getSigners();

        ownerAddress = owner;
        warlock = addr1;
    });

    it('mint on chain A', async () => {
        const tokenId = 0;
        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainA.connect(ownerAddress).mint(ownerAddress.address);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainA.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721_chainA.ownerOf(tokenId)).to.be.equal(ownerAddress.address);
    });

    it('mint on chain B', async () => {
        const tokenId = 334;
        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainB.connect(ownerAddress).mint(ownerAddress.address);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(ownerAddress.address);
    });
});
