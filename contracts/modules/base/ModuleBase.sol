// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../core/AppStorage.sol";
import "../../core/AEDConstants.sol";
import "../../core/interfaces/IAEDModule.sol";
import "../../core/interfaces/IAEDCore.sol";
import "../../libraries/LibAppStorage.sol";

/**
 * @title ModuleBase
 * @dev Stateless base module providing access to shared AppStorage and utility modifiers
 */
abstract contract ModuleBase is AEDConstants, IAEDModule{
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);

    function s() internal pure returns (AppStorage storage) {
        return LibAppStorage.getStorage();
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(s().domains[tokenId].owner == msg.sender, "Not token owner");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(s().domains[tokenId].owner != address(0), "Token does not exist");
        _;
    }

    modifier hasFeature(uint256 tokenId, uint256 feature) {
        require(s().domainFeatures[tokenId] & feature != 0, "Feature not enabled");
        _;
    }

    function _setFeature(uint256 tokenId, uint256 feature) internal {
        s().domainFeatures[tokenId] |= feature;
        emit FeatureEnabled(tokenId, feature);
    }

    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return IAEDCore(address(this)).hasRole(role, account);
    }

    function moduleVersion() external pure virtual override returns (uint256) {
        return 1;
    }
}