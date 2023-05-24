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

        // generate a proxy to allow it to go ONFT
        diamondAddressA = await deployDiamondA();

        eRC721_chainA = await ethers.getContractAt('ERC721', diamondAddressA);

        mintFacet_chainA = await ethers.getContractAt('MintFacet', diamondAddressA);

        renderFacet_chainA = await ethers.getContractAt('RenderFacet', diamondAddressA);

        offsetted = (...arr) => offsettedIndex(startTokenId, arr);

        const [owner, addr1] = await ethers.getSigners();

        ownerAddress = owner;
        warlock = addr1;
    });

    it('mint on chain A and read tokenUI', async () => {
        const tokenId = 0;
        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainA.connect(ownerAddress).mint();

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainA.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721_chainA.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        console.log('Token URI ------>', await renderFacet_chainA.tokenURI(tokenId));
    });
});
