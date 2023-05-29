/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployERC721DiamondB} = require('../scripts/deployERC721_b.js');
const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

const {ethers} = require('hardhat');

let offsetted;

describe('ERC721 TokenURI Rendering', async () => {
    // Diamond contracts
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

        renderFacet_chain = await ethers.getContractAt('RenderFacet', diamondERC721AddressB);

        const [owner, addr1] = await ethers.getSigners();

        ownerAddress = owner;
        warlock = addr1;
    });

    it('mint on chain A and read tokenUI', async () => {
        const tokenId = 1;
        expect(await eRC721_chainB.connect(ownerAddress).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacetERC721_chainB.mint(ownerAddress.address, tokenId);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        console.log('Token URI ------>', await renderFacet_chain.tokenURI(tokenId));
    });
});
