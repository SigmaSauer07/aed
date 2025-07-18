// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDMinting {
    function registerDomain(string calldata name, string calldata tld, bool enableSubdomains) external payable returns (uint256);
    function mintSubdomain(uint256 parentId, string calldata label) external payable returns (uint256);
    function calculateSubdomainFee(uint256 parentId) external view returns (uint256);
}
