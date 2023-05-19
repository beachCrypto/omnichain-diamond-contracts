// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../libraries/LibDiamond.sol';
import '../layerZeroInterfaces/ILayerZeroReceiver.sol';
import '../layerZeroInterfaces/ILayerZeroUserApplicationConfig.sol';
import '../layerZeroInterfaces/ILayerZeroEndpoint.sol';
import {NonblockingLzAppStorage} from './NonblockingLzAppStorage.sol';
import 'hardhat/console.sol';

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzAppUpgradeable is ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    // LZAPP
    ILayerZeroEndpoint public lzEndpoint;

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external {
        LibDiamond.enforceIsContractOwner();

        NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_srcChainId] = _srcAddress;

        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override {}

    function setSendVersion(uint16 _version) external override {}

    function setReceiveVersion(uint16 _version) external override {}

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {}
}
