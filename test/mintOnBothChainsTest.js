/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployDiamondA} = require('../scripts/deployA.js');
const {deployDiamondB} = require('../scripts/deployB.js');

const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

// Layer Zero

const {ethers} = require('hardhat');

let offsetted;

describe('sendFrom()', async () => {
    let diamondAddressA;
    let diamondAddressB;
    let mintFacetA;
    let eRC721AUpgradeableA;
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

        diamondAddressA = await deployDiamondA();
        diamondAddressB = await deployDiamondB();

        mintFacetA = await ethers.getContractAt('MintFacet', diamondAddressA);
        mintFacetB = await ethers.getContractAt('MintFacet', diamondAddressB);

        eRC721AUpgradeableA = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressA);
        eRC721AUpgradeableB = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressB);

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

    it('mint on chain A', async () => {
        expect(await eRC721AUpgradeableA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacetA.connect(ownerAddress).mint(1);

        // verify the owner of the token is on the source chain
        expect(await eRC721AUpgradeableA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721AUpgradeableA.ownerOf(0)).to.be.equal(ownerAddress.address);
    });

    it('mint on chain B', async () => {
        expect(await eRC721AUpgradeableB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacetB.connect(ownerAddress).mint(1);

        // verify the owner of the token is on the source chain
        expect(await eRC721AUpgradeableB.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721AUpgradeableB.ownerOf(0)).to.be.equal(ownerAddress.address);
    });
});
