// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

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

    function isTokenOwner(uint256 tokenId, address account) internal view returns (bool) {
        return getStorage().owners[tokenId] == account;
    }

    function tokenExists(uint256 tokenId) internal view returns (bool) {
        return getStorage().owners[tokenId] != address(0);
    }

    function hasFeature(uint256 tokenId, uint256 feature) internal view returns (bool) {
        return (getStorage().domainFeatures[tokenId] & feature) != 0;
    }

    function setFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = getStorage();
        s.domainFeatures[tokenId] |= feature;
        emit FeatureEnabled(tokenId, feature);
    }

    function removeFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = getStorage();
        s.domainFeatures[tokenId] &= ~feature;
        emit FeatureDisabled(tokenId, feature);
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return getStorage().roles[role][account];
    }

    function moduleVersion() internal pure returns (uint256) {
        return 1;
    }

    function validateTokenOwnership(uint256 tokenId, address account) internal view {
        require(tokenExists(tokenId), "Token does not exist");
        require(isTokenOwner(tokenId, account), "Not token owner");
    }

    function validateFeature(uint256 tokenId, uint256 feature) internal view {
        require(hasFeature(tokenId, feature), "Feature not enabled");
    }
}

