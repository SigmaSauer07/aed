// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDRegistry {
    function enableFeature(uint256 tokenId, uint256 feature) external;
    function disableFeature(uint256 tokenId, uint256 feature) external;
    function hasFeature(uint256 tokenId, uint256 feature) external view returns (bool);
    function linkExternalDomain(string calldata externalDomain, uint256 tokenId) external payable;
    function unlinkExternalDomain(string calldata externalDomain) external;
    function getLinkedDomain(string calldata externalDomain) external view returns (uint256);
}
