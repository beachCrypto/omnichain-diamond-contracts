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

        // console.log('lzEndpointMockA', lzEndpointMockA.address);
        // console.log('lzEndpointMockB', lzEndpointMockB.address);
        // lzEndpointMockA 0x5FbDB2315678afecb367f032d93F642f64180aa3
        // lzEndpointMockB 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
        // A will be Goerli
        // B will be Polygon

        // generate a proxy to allow it to go ONFT
        diamondAddressA = await deployDiamondA();
        diamondAddressB = await deployDiamondB();

        mintFacetA = await ethers.getContractAt('MintFacet', diamondAddressA);
        mintFacetB = await ethers.getContractAt('MintFacet', diamondAddressB);

        eRC721AUpgradeableA = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressA);
        eRC721AUpgradeableB = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressB);

        oNFT721UpgradeableA = await ethers.getContractAt('ONFT721Upgradeable', diamondAddressA);
        oNFT721UpgradeableB = await ethers.getContractAt('ONFT721Upgradeable', diamondAddressB);

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

    it('sendFrom() - your own tokens', async () => {
        await mintFacetA.connect(ownerAddress).mint(1);

        // verify the owner of the token is on the source chain
        expect(await eRC721AUpgradeableA.ownerOf(0)).to.be.equal(ownerAddress.address);

        // token doesn't exist on other chain
        await expect(eRC721AUpgradeableB.ownerOf(0)).to.be.revertedWith('OwnerQueryForNonexistentToken()');

        // can transfer token on srcChain as regular erC721
        await eRC721AUpgradeableA.transferFrom(ownerAddress.address, warlock.address, 0);

        expect(await eRC721AUpgradeableA.ownerOf(0)).to.be.equal(warlock.address);

        // approve the proxy to swap your token
        await eRC721AUpgradeableA.connect(warlock).approve(eRC721AUpgradeableA.address, 0);

        // estimate nativeFees
        let nativeFee = (await oNFT721UpgradeableA.estimateSendFee(chainId_B, warlock.address, 0, false, '0x'))
            .nativeFee;

        console.log('nativeFee', nativeFee.toString());

        // swaps token to other chain
        await oNFT721UpgradeableA
            .connect(warlock)
            .sendFrom(
                warlock.address,
                chainId_B,
                warlock.address,
                0,
                warlock.address,
                ethers.constants.AddressZero,
                '0x',
                {value: nativeFee}
            );
    });
});
