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
    let eRC721_chainB;
    let mintFacet_chainA;
    let mintFacet_chainB;
    let NonblockingLzAppUpgradeableA;
    let NonblockingLzAppUpgradeableB;
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

        // Hardhat local network information
        // console.log('lzEndpointMockA', lzEndpointMockA.address);
        // console.log('lzEndpointMockB', lzEndpointMockB.address);
        // lzEndpointMockA 0x5FbDB2315678afecb367f032d93F642f64180aa3
        // lzEndpointMockB 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
        // A
        // B

        // generate a proxy to allow it to go ONFT
        diamondAddressA = await deployDiamondA();
        diamondAddressB = await deployDiamondB();

        eRC721_chainA = await ethers.getContractAt('ERC721', diamondAddressA);
        eRC721_chainB = await ethers.getContractAt('ERC721', diamondAddressB);

        mintFacet_chainA = await ethers.getContractAt('MintFacet', diamondAddressA);
        mintFacet_chainB = await ethers.getContractAt('MintFacet', diamondAddressB);

        NonblockingLzAppUpgradeableA = await ethers.getContractAt('NonblockingLzAppUpgradeable', diamondAddressA);
        NonblockingLzAppUpgradeableB = await ethers.getContractAt('NonblockingLzAppUpgradeable', diamondAddressB);

        renderFacet_chainA = await ethers.getContractAt('RenderFacet', diamondAddressA);
        renderFacet_chainB = await ethers.getContractAt('RenderFacet', diamondAddressB);

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

    it('sendFrom() - your own tokens', async () => {
        const tokenId = 123;
        await mintFacet_chainA.connect(ownerAddress).mint(ownerAddress.address, tokenId);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainA.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        await expect(eRC721_chainB.ownerOf(tokenId)).to.be.revertedWith('ERC721: invalid token ID');

        // can transfer token on srcChain as regular erC721
        await eRC721_chainA.transferFrom(ownerAddress.address, warlock.address, tokenId);

        expect(await eRC721_chainA.ownerOf(tokenId)).to.be.equal(warlock.address);

        // approve the proxy to swap your token
        await eRC721_chainA.connect(warlock).approve(eRC721_chainA.address, tokenId);

        console.log(
            'Token URI from contract token was minted chain A ------>',
            await renderFacet_chainA.tokenURI(tokenId)
        );

        // estimate nativeFees
        let nativeFee = (await eRC721_chainA.estimateSendFee(chainId_B, warlock.address, tokenId, false, '0x'))
            .nativeFee;

        // swaps token to other chain
        await eRC721_chainA
            .connect(warlock)
            .sendFrom(
                warlock.address,
                chainId_B,
                warlock.address,
                tokenId,
                warlock.address,
                ethers.constants.AddressZero,
                '0x',
                {value: nativeFee}
            );

        // token is burnt
        expect(await eRC721_chainA.ownerOf(tokenId)).to.be.equal(eRC721_chainA.address);

        // token received on the dst chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(warlock.address);

        console.log('Token URI after transfer on chainB ------>', await renderFacet_chainB.tokenURI(tokenId));

        // estimate nativeFees

        nativeFee = (
            await eRC721_chainB.estimateSendFee(chainId_A, warlock.address, tokenId, false, defaultAdapterParams)
        ).nativeFee;

        // can send to other onft contract eg. not the original nft contract chain
        await eRC721_chainB
            .connect(warlock)
            .sendFrom(
                warlock.address,
                chainId_A,
                warlock.address,
                tokenId,
                warlock.address,
                ethers.constants.AddressZero,
                '0x',
                {value: nativeFee}
            );

        // token is burned on the sending chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(eRC721_chainB.address);
    });
});
