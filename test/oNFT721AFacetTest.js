/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployDiamondA} = require('../scripts/deployA.js');

const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

// Layer Zero

const {ethers} = require('hardhat');

let offsetted;

describe('sendFrom()', async () => {
    let diamondAddressA;
    let mintFacetA;
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

        // console.log('lzEndpointMockA', lzEndpointMockA.address);
        // console.log('lzEndpointMockB', lzEndpointMockB.address);
        // lzEndpointMockA 0x5FbDB2315678afecb367f032d93F642f64180aa3
        // lzEndpointMockB 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
        // A will be Goerli
        // B will be Polygon

        diamondAddressA = await deployDiamondA();

        mintFacetA = await ethers.getContractAt('MintFacet', diamondAddressA);

        eRC721AUpgradeableA = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressA);

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

    it('sendFrom() - your own tokens', async () => {
        await mintFacetA.connect(ownerAddress).mint(1);

        // verify the owner of the token is on the source chain
        expect(await eRC721AUpgradeableA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721AUpgradeableA.ownerOf(0)).to.be.equal(ownerAddress.address);

        // can transfer token on srcChain as regular erC721
        await eRC721AUpgradeableA.transferFrom(ownerAddress.address, warlock.address, 0);

        // Token left wallet of previous owner
        expect(await eRC721AUpgradeableA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        // Token arrived in wallet of new owner
        expect(await eRC721AUpgradeableA.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        // Owner of token equals new owner
        expect(await eRC721AUpgradeableA.connect(warlock.address).ownerOf(0)).to.equal(warlock.address);

        // approve the proxy to swap your token
        await eRC721AUpgradeableA.connect(warlock).approve(eRC721AUpgradeableA.address, 0);
    });
});
