// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDAdmin {
    // Events
    event FeeRecipientUpdated(address indexed newRecipient);
    event SubdomainSettingsUpdated(uint256 newMax, uint256 newBasePrice, uint256 newMultiplier);
    event ContractPaused();
    event ContractUnpaused();
    
    // Functions
    function updateFee(string calldata feeType, uint256 newAmount) external;
    function updateFeeRecipient(address newRecipient) external;
    function configureTLD(string calldata tld, bool isActive, uint256 price) external;
    function updateSubdomainSettings(uint256 newMax, uint256 newBasePrice, uint256 newMultiplier) external;
    function getFee(string calldata feeType) external view returns (uint256);
    function isTLDActive(string calldata tld) external view returns (bool);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function pause() external;
    function unpause() external;
}
