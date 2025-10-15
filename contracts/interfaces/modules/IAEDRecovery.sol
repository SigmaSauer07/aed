// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDRecovery {
    function addGuardian(uint256 tokenId, address guardian) external;
    function removeGuardian(uint256 tokenId, address guardian) external;
    function initiateRecovery(uint256 tokenId, address newOwner) external;
    function confirmRecovery(uint256 tokenId) external;
    function cancelRecovery(uint256 tokenId) external;
    function executeRecovery(uint256 tokenId) external;
    function getGuardians(uint256 tokenId) external view returns (address[] memory);
    function getRecoveryInfo(uint256 tokenId) external view returns (
        address newOwner,
        uint256 confirmations,
        uint256 requiredConfirmations,
        uint256 deadline,
        bool isActive
    );
    function isGuardian(uint256 tokenId, address account) external view returns (bool);
}
