// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";
import {ERC165Upgradeable} from "../../utils/introspection/ERC165Upgradeable.sol";
import {IERC721Upgradeable} from "./IERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from "./IERC721MetadataUpgradeable.sol";

/// @notice Lightweight ERC721 base contract exposing metadata helpers while leaving token storage to the inheriting contract.
abstract contract ERC721Upgradeable is ContextUpgradeable, ERC165Upgradeable, IERC721MetadataUpgradeable {
    string private _name;
    string private _symbol;

    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory);

    function balanceOf(address owner) public view virtual override returns (uint256);

    function ownerOf(uint256 tokenId) public view virtual override returns (address);

    function approve(address to, uint256 tokenId) public virtual override;

    function getApproved(uint256 tokenId) public view virtual override returns (address);

    function setApprovalForAll(address operator, bool approved) public virtual override;

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public virtual override;

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override;
}
