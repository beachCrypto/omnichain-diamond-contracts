/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployDiamond} = require('../scripts/deploy.js');

const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

// Layer Zero

const {ethers} = require('hardhat');

let offsetted;

describe('Mint', async () => {
    let diamondAddress;
    let mintFacet;
    let eRC721AUpgradeable;
    let address1;
    let address2;
    let address3;
    let owner;

    // Layer Zero

    const chainId_A = 1;
    const chainId_B = 2;
    const name = 'OmnichainNonFungibleToken';
    const symbol = 'ONFT';
    const minGasToStore = 150000;
    const batchSizeLimit = 300;
    const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 200000]);

    before(async function () {});

    beforeEach(async () => {
        diamondAddress = await deployDiamond();

        mintFacet = await ethers.getContractAt('MintFacet', diamondAddress);

        eRC721AUpgradeable = await ethers.getContractAt('ERC721AUpgradeable', diamondAddress);

        startTokenId = 0;

        offsetted = (...arr) => offsettedIndex(startTokenId, arr);

        const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

        warlock = addr1;
        ownerAddress = owner;

        warlock.expected = {
            mintCount: 2,
            tokens: [offsetted(0, 1)],
        };

        ownerAddress.expected = {
            mintCount: 2,
            tokens: offsetted(2, 3),
        };
    });

    it('Sender can mint an NFT', async () => {
        expect(await eRC721AUpgradeable.connect(warlock.address).balanceOf(warlock.address)).to.equal(0);

        await mintFacet.connect(warlock).mint(1);

        expect(await eRC721AUpgradeable.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);
    });
});
