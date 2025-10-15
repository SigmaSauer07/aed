// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IERC721Extended {
    function exists(uint256 tokenId) external view returns (bool);
    function isApproved(address spender, uint256 tokenId) external view returns (bool);
}
