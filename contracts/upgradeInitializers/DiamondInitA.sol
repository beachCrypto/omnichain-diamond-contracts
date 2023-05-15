// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

// Diamond interfaces
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {IDiamondLoupe} from '../interfaces/IDiamondLoupe.sol';
import {IDiamondCut} from '../interfaces/IDiamondCut.sol';

// ERC721 interfaces
import {IERC173} from '../interfaces/IERC173.sol';
import {IERC165} from '../interfaces/IERC165.sol';
import {IERC721} from '../ERC721-Contracts/IERC721.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

// ERC721 Storage
import {ERC721Storage} from '../../contracts/ERC721-Contracts/ERC721.sol';

// LayerZero interfaces
import {IONFT721CoreUpgradeable} from '../layerZeroUpgradeable/IONFT721CoreUpgradeable.sol';
import {ILayerZeroReceiver} from '../layerZeroInterfaces/ILayerZeroReceiver.sol';
import {ILayerZeroEndpoint} from '../layerZeroInterfaces/ILayerZeroEndpoint.sol';
import {ILayerZeroUserApplicationConfig} from '../layerZeroInterfaces/ILayerZeroUserApplicationConfig.sol';

// LayerZero Storage
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInitA {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init() external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IONFT721CoreUpgradeable).interfaceId] = true;
        ds.supportedInterfaces[type(ILayerZeroReceiver).interfaceId] = true;
        ds.supportedInterfaces[type(ILayerZeroEndpoint).interfaceId] = true;
        ds.supportedInterfaces[type(ILayerZeroUserApplicationConfig).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        // Initialize ERC721A state variables
        ERC721Storage.Layout storage l = ERC721Storage.layout();
        l._name = 'Dirt Bikes';
        l._symbol = 'Brap';

        // Initialize LayerZero state variables
        // Chain A

        LayerZeroEndpointStorage.LayerZeroSlot storage lzep = LayerZeroEndpointStorage.layerZeroEndpointSlot();
        lzep.lzEndpoint = ILayerZeroEndpoint(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    }
}
