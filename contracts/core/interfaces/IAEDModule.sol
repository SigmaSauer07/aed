// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDModule {
    function moduleId() external pure returns (bytes32);
    function moduleVersion() external pure returns (uint256);
    function moduleName() external pure returns (string memory);
    function dependencies() external pure returns (bytes32[] memory);
    function getSelectors() external pure returns (bytes4[] memory);
    function initialize(bytes calldata data) external;
    function initializeModule() external;
    function isInitialized() external view returns (bool);
    function isEnabled() external view returns (bool);
    function enable() external;
    function disable() external;
}
