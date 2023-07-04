// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @author beachcrypto.eth
 * @title Dirt Bikes Omnichain Diamond NFTs
 *
 * ONFT721 using EIP 2535: Diamonds, Multi-Facet Proxy
 *
 *  */

import './IERC721Receiver.sol';
import {IONFT721CoreUpgradeable} from '../ONFT-Contracts/IONFT721CoreUpgradeable.sol';
import '../layerZeroUpgradeable/NonblockingLzAppUpgradeable.sol';
import '../libraries/LibDiamond.sol';

import {ERC721Internal} from './ERC721Internal.sol';
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';
import {NonblockingLzAppStorage} from '../layerZeroUpgradeable/NonblockingLzAppStorage.sol';
import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';

// import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';
import {ONFTStorage} from '../ONFT-Contracts/ONFTStorage.sol';

import 'hardhat/console.sol';

contract ERC721 is ERC721Internal, NonblockingLzAppUpgradeable, IONFT721CoreUpgradeable {
    using ExcessivelySafeCall for address;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);

    event ReceiveFromChain(
        uint16 indexed _srcChainId,
        bytes indexed _srcAddress,
        address indexed _toAddress,
        uint _tokenId,
        uint64 _nonce
    );

    event SendToChain(
        address indexed _sender,
        uint16 indexed _dstChainId,
        bytes indexed _toAddress,
        uint _tokenId,
        uint64 _nonce
    );

    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    uint public constant NO_EXTRA_GAS = 0;
    uint public constant FUNCTION_TYPE_SEND = 1;
    bool public useCustomAdapterParams;

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

    function name() public view virtual returns (string memory) {
        return _name();
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol();
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), 'ERC721: address zero is not a valid owner');
        return _balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), 'ERC721: invalid token ID');
        return owner;
    }

    function rawOwnerOf(uint256 tokenId) public view returns (address) {
        if (_exists(tokenId)) {
            return ownerOf(tokenId);
        }
        return address(0);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = _ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721: approve caller is not token owner or approved for all'
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: caller is not token owner or approved');

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: caller is not token owner or approved');
        _safeTransfer(from, to, tokenId, data);
    }

    // =============================================================
    //                      LZ Send Operations
    // =============================================================

    function estimateSendFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        bool _useZro,
        bytes memory _adapterParams
    ) public view virtual override returns (uint nativeFee, uint zroFee) {
        return estimateSendBatchFee(_dstChainId, _toAddress, _toSingletonArray(_tokenId), _useZro, _adapterParams);
    }

    function estimateSendBatchFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        bool _useZro,
        bytes memory _adapterParams
    ) public view virtual override returns (uint nativeFee, uint zroFee) {
        bytes memory payload = abi.encode(_toAddress, _tokenIds);
        return
            LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                payload,
                _useZro,
                _adapterParams
            );
    }

    function _toSingletonArray(uint element) internal pure returns (uint[] memory) {
        uint[] memory array = new uint[](1);
        array[0] = element;
        return array;
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), 'ONFT721: send caller is not owner nor approved');
        require(ownerOf(_tokenId) == _from, 'ONFT721: send from incorrect owner');
        _transfer(_from, address(this), _tokenId);
    }

    function _checkGasLimit(uint16 _dstChainId, uint _type, bytes memory _adapterParams, uint _extraGas) internal view {
        uint providedGasLimit = getGasLimit(_adapterParams);
        uint minGasLimit = NonblockingLzAppStorage.nonblockingLzAppSlot().minDstGasLookup[_dstChainId][_type] +
            _extraGas;
        require(minGasLimit > 0, 'LzApp: minGasLimit not set');
        require(providedGasLimit >= minGasLimit, 'LzApp: gas limit is too low');
    }

    function getGasLimit(bytes memory _adapterParams) public pure returns (uint gasLimit) {
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual override {
        _send(
            _from,
            _dstChainId,
            _toAddress,
            _toSingletonArray(_tokenId),
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function sendBatchFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _tokenIds, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        // allow 1 by default
        require(_tokenIds.length > 0, 'LzApp: tokenIds[] is empty');
        require(
            _tokenIds.length == 1 ||
                _tokenIds.length <= ONFTStorage.oNFTStorageLayout().dstChainIdToBatchLimit[_dstChainId],
            'ONFT721: batch size exceeds dst batch limit'
        );

        for (uint i = 0; i < _tokenIds.length; i++) {
            _debitFrom(_from, _dstChainId, _toAddress, _tokenIds[i]);
        }

        bytes memory payload = abi.encode(_toAddress, _tokenIds);

        _checkGasLimit(
            _dstChainId,
            FUNCTION_TYPE_SEND,
            _adapterParams,
            ONFTStorage.oNFTStorageLayout().dstChainIdToTransferGas[_dstChainId] * _tokenIds.length
        );
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit SendToChain(_dstChainId, _from, _toAddress, _tokenIds);
    }

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, 'LzApp: destination chain is not a trusted source');
        _checkPayloadSize(_dstChainId, _payload.length);
        LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.send{value: _nativeFee}(
            _dstChainId,
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    // =============================================================
    //                     LZ Receive Operations
    // =============================================================

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(
            _msgSender() == address(LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint),
            'LzApp: invalid endpoint caller'
        );

        bytes memory trustedRemote = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length &&
                trustedRemote.length > 0 &&
                keccak256(_srcAddress) == keccak256(trustedRemote),
            'LzApp: invalid source sending contract'
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload)
        );
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _storeFailedMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload,
        bytes memory _reason
    ) internal virtual {
        NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(
            _payload
        );
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), 'NonblockingLzApp: caller must be LzApp');
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal virtual {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint[] memory tokenIds) = abi.decode(_payload, (bytes, uint[]));

        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        // for (uint i = 0; i < tokenIds.length; i++) {
        //     uint256 randomHash = DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[tokenId];

        //     if (randomHash == 0) {
        //         // Store psuedo-randomHash as DirtBike VIN
        //         DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[tokenId] = _randomHash;
        //     }
        // }

        uint nextIndex = _creditTill(_srcChainId, toAddress, 0, tokenIds);
        if (nextIndex < tokenIds.length) {
            // not enough gas to complete transfers, store to be cleared in another tx
            bytes32 hashedPayload = keccak256(_payload);
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload] = ONFTStorage.StoredCredit(
                _srcChainId,
                toAddress,
                nextIndex,
                true
            );
            emit CreditStored(hashedPayload, _payload);
        }

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenIds);
    }

    function clearCredits(bytes memory _payload) external {
        bytes32 hashedPayload = keccak256(_payload);
        require(
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].creditsRemain,
            'ONFT721: no credits stored'
        );

        (, uint[] memory tokenIds) = abi.decode(_payload, (bytes, uint[]));

        uint nextIndex = _creditTill(
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].srcChainId,
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].toAddress,
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].index,
            tokenIds
        );
        require(
            nextIndex > ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].index,
            'ONFT721: not enough gas to process credit transfer'
        );

        if (nextIndex == tokenIds.length) {
            // cleared the credits, delete the element
            delete ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload];
            emit CreditCleared(hashedPayload);
        } else {
            // store the next index to mint
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload] = ONFTStorage.StoredCredit(
                ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].srcChainId,
                ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].toAddress,
                nextIndex,
                true
            );
        }
    }

    // When a srcChain has the ability to transfer more chainIds in a single tx than the dst can do.
    // Needs the ability to iterate and stop if the minGasToTransferAndStore is not met
    function _creditTill(
        uint16 _srcChainId,
        address _toAddress,
        uint _startIndex,
        uint[] memory _tokenIds
    ) internal returns (uint256) {
        uint i = _startIndex;
        while (i < _tokenIds.length) {
            // if not enough gas to process, store this index for next loop
            if (gasleft() < ONFTStorage.oNFTStorageLayout().minGasToTransferAndStore) break;

            _creditTo(_srcChainId, _toAddress, _tokenIds[i]);
            i++;
        }

        // indicates the next index to send of tokenIds,
        // if i == tokenIds.length, we are finished
        return i;
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal virtual {
        require(!_exists(_tokenId) || (_exists(_tokenId) && ownerOf(_tokenId) == address(this)));
        if (!_exists(_tokenId)) {
            _safeMint(_toAddress, _tokenId);
        } else {
            _transfer(address(this), _toAddress, _tokenId);
        }
    }

    function setMinGasToTransferAndStore(uint256 _minGasToTransferAndStore) external {
        LibDiamond.enforceIsContractOwner();
        require(_minGasToTransferAndStore > 0, 'ONFT721: minGasToTransferAndStore must be > 0');
        ONFTStorage.oNFTStorageLayout().minGasToTransferAndStore = _minGasToTransferAndStore;
    }

    // limit on src the amount of tokens to batch send
    function setDstChainIdToBatchLimit(uint16 _dstChainId, uint256 _dstChainIdToBatchLimit) external {
        LibDiamond.enforceIsContractOwner();
        require(_dstChainIdToBatchLimit > 0, 'ONFT721: dstChainIdToBatchLimit must be > 0');
        ONFTStorage.oNFTStorageLayout().dstChainIdToBatchLimit[_dstChainId] = _dstChainIdToBatchLimit;
    }

    // =============================================================
    //                      Non blocking receive
    // =============================================================

    // we are here ================================================

    function retryMessage(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public payable {
        // assert there is message to retry
        bytes32 payloadHash = NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][
            _nonce
        ];
        require(payloadHash != bytes32(0), 'NonblockingLzApp: no stored message');
        require(keccak256(_payload) == payloadHash, 'NonblockingLzApp: invalid payload');
        // clear the stored message
        NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}
