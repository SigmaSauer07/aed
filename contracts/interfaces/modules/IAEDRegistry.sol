// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDRegistry {
    function setFeature(uint256 tokenId, uint256 feature) external;
    function removeFeature(uint256 tokenId, uint256 feature) external;
    function isBYODomain(string calldata domain) external view returns (bool);
}
