// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

library LibModule {
    using LibAppStorage for AppStorage;


    function computeModuleId(string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function getStorage() internal view returns (AppStorage storage) {
        return LibAppStorage.appStorage();
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(getStorage().domains[tokenId].owner == msg.sender, "Not token owner");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(getStorage().domains[tokenId].owner != address(0), "Token does not exist");
        _;
    }

    modifier hasFeature(uint256 tokenId, uint256 feature) {
        require(getStorage().domainFeatures[tokenId] & feature != 0, "Feature not enabled");
        _;
    }

    function _setFeature(uint256 tokenId, uint256 feature) internal {
        getStorage().domainFeatures[tokenId] |= feature;
        emit FeatureEnabled(uint32, true);
    }

    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return Domain.IAEDCore(address(this)).hasRole(role, account);
    }

    function moduleVersion() external pure virtual returns (uint256) {
        return 1;
    }
}

