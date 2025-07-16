// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDReverse {
    function setReverseRecord(uint256 tokenId) external;
    function getReverseRecord(address user) external view returns (uint256);
}
