// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDModule {
    function moduleId() external pure returns (bytes32);
    function moduleVersion() external pure returns (uint256);
    function dependencies() external pure returns (bytes32[] memory);
    function initialize(bytes calldata data) external;
    function isEnabled() external view returns (bool);
    function moduleName() external pure returns (string memory);
    function getSelectors() external pure returns (bytes4[] memory);
    function initializeModule() external;
    function isInitialized() external view returns (bool);
    function disable() external;
    function enable() external;    
}