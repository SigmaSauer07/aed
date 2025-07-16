// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDMetadata {
    function setProfileURI(uint256 tokenId, string calldata uri) external;
    function setImageURI(uint256 tokenId, string calldata uri) external;
}
