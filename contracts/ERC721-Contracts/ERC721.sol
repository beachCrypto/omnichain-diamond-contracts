// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../libraries/LibDiamond.sol';
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';
import {NonblockingLzAppStorage} from '../layerZeroUpgradeable/NonblockingLzAppStorage.sol';
import './IERC721Receiver.sol';
import '../utils/Strings.sol';
import '../layerZeroUpgradeable/IONFT721CoreUpgradeable.sol';
import '../layerZeroUpgradeable/NonblockingLzAppUpgradeable.sol';
import {ERC721Internal} from './ERC721Internal.sol';

import 'hardhat/console.sol';

contract ERC721 is ERC721Internal, NonblockingLzAppUpgradeable {
    using Strings for uint256;

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

    // TODO Storage for Token URI
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
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
        bytes calldata _toAddress,
        uint _tokenId,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint nativeFee, uint zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(_toAddress, _tokenId);

        return
            LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                payload,
                _useZro,
                _adapterParams
            );
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external {
        LibDiamond.enforceIsContractOwner();

        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), 'ONFT721: send caller is not owner nor approved');
        require(_ownerOf(_tokenId) == _from, 'ONFT721: send from incorrect owner');
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
    ) public payable virtual {
        _send(_from, _dstChainId, _toAddress, _tokenId, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        _debitFrom(_from, _dstChainId, _toAddress, _tokenId);

        bytes memory payload = abi.encode(_toAddress, _tokenId);

        if (NonblockingLzAppStorage.nonblockingLzAppSlot().useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, FUNCTION_TYPE_SEND, _adapterParams, NO_EXTRA_GAS);
        } else {
            require(_adapterParams.length == 0, 'LzApp: _adapterParams must be empty.');
        }

        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams);

        uint64 nonce = LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.getOutboundNonce(
            _dstChainId,
            address(this)
        );
        emit SendToChain(_from, _dstChainId, _toAddress, _tokenId, nonce);
    }

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        bytes memory trustedRemote = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_dstChainId];

        require(trustedRemote.length != 0, 'LzApp: destination chain is not a trusted source');

        LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.send{value: msg.value}(
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
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(
            msg.sender == address(LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint),
            'LzApp: invalid endpoint caller'
        );

        bytes memory trustedRemote = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_srcChainId];

        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length && keccak256(_srcAddress) == keccak256(trustedRemote),
            'LzApp: invalid source sending contract'
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual {
        // try-catch all errors/exceptions
        try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(
                _payload
            );
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual {
        // only internal transaction
        require(msg.sender == address(this), 'NonblockingLzApp: caller must be LzApp');
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint tokenId) = abi.decode(_payload, (bytes, uint));
        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        _creditTo(_srcChainId, toAddress, tokenId);

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenId, _nonce);
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal virtual {
        require(!_exists(_tokenId) || (_exists(_tokenId) && _ownerOf(_tokenId) == address(this)));
        if (!_exists(_tokenId)) {
            _safeMint(_toAddress, _tokenId);
        } else {
            transferFrom(address(this), _toAddress, _tokenId);
        }
    }
}