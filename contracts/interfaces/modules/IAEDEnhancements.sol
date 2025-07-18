// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDEnhancements {
    function purchaseFeature(uint256 tokenId, string calldata featureName) external payable;
    function enableSubdomains(uint256 tokenId) external payable;
    function upgradeExternalDomain(string calldata externalDomain) external payable;
    function getFeaturePrice(string calldata featureName) external view returns (uint256);
    function isFeatureEnabled(uint256 tokenId, string calldata featureName) external view returns (bool);
    function getAvailableFeatures() external view returns (string[] memory);
}
