/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployDiamond} = require('../scripts/deploy.js');

const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

let offsetted;

describe('Mint', async () => {
    let diamondAddress;
    let mintFacet;
    let eRC721AUpgradeable;
    let address1;
    let address2;
    let address3;
    let owner;

    before(async function () {});

    beforeEach(async () => {
        diamondAddress = await deployDiamond();

        mintFacet = await ethers.getContractAt('MintFacet', diamondAddress);

        eRC721AUpgradeable = await ethers.getContractAt('ERC721AUpgradeable', diamondAddress);

        startTokenId = 0;

        offsetted = (...arr) => offsettedIndex(startTokenId, arr);

        const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

        address1 = addr1;
        address2 = addr2;
        address3 = addr3;
        ownerAddress = owner;

        address1.expected = {
            mintCount: 1,
            tokens: [offsetted(0)],
        };

        address2.expected = {
            mintCount: 2,
            tokens: offsetted(1, 2),
        };

        address3.expected = {
            mintCount: 4,
            tokens: offsetted(3, 4, 5, 6),
        };

        ownerAddress.expected = {
            mintCount: 2,
            tokens: offsetted(7, 8),
        };
    });

    it('Sender can mint an NFT', async () => {
        expect(await eRC721AUpgradeable.connect(address1.address).balanceOf(address1.address)).to.equal(0);

        await mintFacet.connect(address1).mint(1);

        expect(await eRC721AUpgradeable.connect(address1.address).balanceOf(address1.address)).to.equal(1);
    });
});
