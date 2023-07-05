/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployERC721ADiamondA} = require('../scripts/deployERC721A_a.js');
const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');
const {ethers} = require('hardhat');

let offsetted;

describe('ERC721 TokenURI Rendering', async () => {
    // Diamond contracts
    let diamondAddressA;
    let owner;
    const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 250000]);

    // Layer Zero
    const chainId_A = 1;
    const name = 'ERC721A';
    const symbol = 'ERC721A Symbol';

    before(async function () {});

    beforeEach(async () => {
        // generate a proxy to allow it to go ONFT
        diamondAddressA = await deployERC721ADiamondA();

        eRC721A_chainA = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressA);

        mintFacet_chainA = await ethers.getContractAt('MintFacet', diamondAddressA);

        renderFacet_chainA = await ethers.getContractAt('RenderFacet', diamondAddressA);

        const [owner, addr1] = await ethers.getSigners();

        ownerAddress = owner;
        warlock = addr1;
    });

    it('mint on chain A and read tokenUI', async () => {
        let tokenId = 4;
        await mintFacet_chainA.mint(5);

        // verify the owner of the token is on the source chain
        expect(await eRC721A_chainA.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        // verify the owner of the token is on the source chain
        expect(await eRC721A_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(5);

        console.log('Token URI ------>', await renderFacet_chainA.tokenURI(tokenId));
        console.log('Token URI ------> 1', await renderFacet_chainA.tokenURI(1));
        console.log('Token URI ------> 2', await renderFacet_chainA.tokenURI(2));
    });
});
