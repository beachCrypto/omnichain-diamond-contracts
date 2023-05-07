// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import '../ERC721A-Upgradeable/ERC721AUpgradeableInternal.sol';
import './ONFT721CoreUpgradeable.sol';

// NOTE: this ONFT contract has no public minting logic.
// must implement your own minting logic in child classes

// TO Do Initialize ONFT721UpgradeableInternal in Diamond
contract ONFT721UpgradeableInternal is ONFT721CoreUpgradeable, ERC721AUpgradeableInternal {
    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal virtual override {
        require(_isSenderApprovedOrOwner(_msgSender(), _tokenId), 'ONFT721: send caller is not owner nor approved');
        require(ERC721AUpgradeableInternal.ownerOf(_tokenId) == _from, 'ONFT721: send from incorrect owner');
        _transfer(_from, address(this), _tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal virtual override {
        require(
            !_exists(_tokenId) || (_exists(_tokenId) && ERC721AUpgradeableInternal.ownerOf(_tokenId) == address(this))
        );
        if (!_exists(_tokenId)) {
            _safeMint(_toAddress, _tokenId);
        } else {
            _transfer(address(this), _toAddress, _tokenId);
        }
    }
}
