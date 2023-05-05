/* global ethers describe before it */
/* eslint-disable prefer-const */

const {assert, expect} = require('chai');
const {ethers, upgrades} = require('hardhat');

const {deployDiamond} = require('../scripts/deploy.js');

const {offsettedIndex} = require('./helpers/helpers.js');

describe('ONFT721: ', function () {
    const chainId_A = 1;
    const chainId_B = 2;
    // const name = 'OmnichainNonFungibleToken';
    // const symbol = 'ONFT';
    const minGasToStore = 150000;
    const batchSizeLimit = 300;
    const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 200000]);

    // Diamond contracts
    let diamondAddressA, mintFacet, eRC721AUpgradeable;

    // Signers
    let owner, warlock, witch, hedwig, errol;

    // Layer Zero contracts
    let lzEndpointMockA, lzEndpointMockB, LZEndpointMock, ONFT, ONFT_A, ONFT_B;

    before(async function () {
        LZEndpointMock = await ethers.getContractFactory('LZEndpointMock');
    });

    beforeEach(async function () {
        lzEndpointMockA = await LZEndpointMock.deploy(chainId_A);
        lzEndpointMockB = await LZEndpointMock.deploy(chainId_B);

        diamondAddress_A = await deployDiamond();

        ONFTMintFacet_A = await ethers.getContractAt('MintFacet', diamondAddress_A);
        ONFTeRC721AUpgradeable_A = await ethers.getContractAt('ERC721AUpgradeable', diamondAddress_A);

        startTokenId = 0;

        offsetted = (...arr) => offsettedIndex(startTokenId, arr);

        owner = (await ethers.getSigners())[0];
        warlock = (await ethers.getSigners())[1];

        warlock.expected = {
            mintCount: 1,
            tokens: [offsetted(0)],
        };

        owner.expected = {
            mintCount: 2,
            tokens: offsetted(1, 2),
        };
    });

    it('sendFrom() - your own tokens', async function () {
        const tokenId = 0;
        await ONFTMintFacet_A.connect(warlock).mint(warlock.expected.mintCount);

        // verify the owner of the token is on the source chain
        expect(await ONFTeRC721AUpgradeable_A.ownerOf(tokenId)).to.be.equal(warlock.address);

        // // token doesn't exist on other chain
        // await expect(ONFT_B.ownerOf(tokenId)).to.be.revertedWith('ERC721: invalid token ID');

        // // can transfer token on srcChain as regular erC721
        // await ONFT_A.transferFrom(owner.address, warlock.address, tokenId);
        // expect(await ONFT_A.ownerOf(tokenId)).to.be.equal(warlock.address);

        // // approve the proxy to swap your token
        // await ONFT_A.connect(warlock).approve(ONFT_A.address, tokenId);

        // // estimate nativeFees
        // let nativeFee = (await ONFT_A.estimateSendFee(chainId_B, warlock.address, tokenId, false, defaultAdapterParams))
        //     .nativeFee;

        // // swaps token to other chain
        // await ONFT_A.connect(warlock).sendFrom(
        //     warlock.address,
        //     chainId_B,
        //     warlock.address,
        //     tokenId,
        //     warlock.address,
        //     ethers.constants.AddressZero,
        //     defaultAdapterParams,
        //     {value: nativeFee}
        // );

        // // token is burnt
        // expect(await ONFT_A.ownerOf(tokenId)).to.be.equal(ONFT_A.address);

        // // token received on the dst chain
        // expect(await ONFT_B.ownerOf(tokenId)).to.be.equal(warlock.address);

        // // estimate nativeFees
        // nativeFee = (await ONFT_B.estimateSendFee(chainId_A, warlock.address, tokenId, false, defaultAdapterParams))
        //     .nativeFee;

        // // can send to other onft contract eg. not the original nft contract chain
        // await ONFT_B.connect(warlock).sendFrom(
        //     warlock.address,
        //     chainId_A,
        //     warlock.address,
        //     tokenId,
        //     warlock.address,
        //     ethers.constants.AddressZero,
        //     defaultAdapterParams,
        //     {value: nativeFee}
        // );

        // // token is burned on the sending chain
        // expect(await ONFT_B.ownerOf(tokenId)).to.be.equal(ONFT_B.address);
    });
});
