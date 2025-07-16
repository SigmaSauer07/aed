// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDEnhancements {
    function unlockFeature(uint256 tokenId, uint256 feature) external payable;
    function isFeatureUnlocked(uint256 tokenId, uint256 feature) external view returns (bool);
}
