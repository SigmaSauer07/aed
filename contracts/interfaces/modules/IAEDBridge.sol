// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDBridge {
    function bridgeDomain(uint256 tokenId, string calldata destination) external;
}
