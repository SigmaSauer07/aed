// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

library LibModule {
    using LibAppStorage for AppStorage;
    
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature, bool enabled);

    function computeModuleId(string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function getStorage() internal view returns (AppStorage storage) {
        return LibAppStorage.s();
    }

    function _setFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = LibAppStorage.s();
        s.domainFeatures[tokenId] |= feature;
        emit FeatureEnabled(tokenId, feature, true);
    }

    function _clearFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = LibAppStorage.s();
        s.domainFeatures[tokenId] &= ~feature;
        emit FeatureEnabled(tokenId, feature, false);
    }

    function _hasFeature(uint256 tokenId, uint256 feature) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.s();
        return (s.domainFeatures[tokenId] & feature) != 0;
    }

    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.s();
        return s.roles[role][account];
    }

    function _isTokenOwner(uint256 tokenId, address account) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.s();
        return s.owners[tokenId] == account;
    }

    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.s();
        return s.owners[tokenId] != address(0);
    }
}

