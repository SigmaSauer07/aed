// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDMetadata {
    function setProfileURI(uint256 tokenId, string calldata uri) external;
    function setImageURI(uint256 tokenId, string calldata uri) external;
    function getProfileURI(uint256 tokenId) external view returns (string memory);
    function getImageURI(uint256 tokenId) external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
