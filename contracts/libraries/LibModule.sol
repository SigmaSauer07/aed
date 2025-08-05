// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

/**
 * @title LibModule
 * @dev Library for module utilities and helpers
 */
library LibModule {
    using LibAppStorage for AppStorage;

    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);

    function computeModuleId(string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function getStorage() internal pure returns (AppStorage storage) {
        return LibAppStorage.appStorage();
    }

    function _setFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = getStorage();
        s.domainFeatures[tokenId] |= feature;
        emit FeatureEnabled(tokenId, feature);
    }

    function _removeFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = getStorage();
        s.domainFeatures[tokenId] &= ~feature;
        emit FeatureDisabled(tokenId, feature);
    }

    function _hasFeature(uint256 tokenId, uint256 feature) internal view returns (bool) {
        return (getStorage().domainFeatures[tokenId] & feature) != 0;
    }

    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return getStorage().owners[tokenId] != address(0);
    }

    function _isTokenOwner(uint256 tokenId, address account) internal view returns (bool) {
        return getStorage().owners[tokenId] == account;
    }
}

