// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDReverse {
    function setReverse(string calldata domain) external;
    function clearReverse() external;
    function getReverse(address addr) external view returns (string memory);
    function getReverseOwner(string calldata domain) external view returns (address);
}
