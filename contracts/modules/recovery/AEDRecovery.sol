// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibRecovery.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDRecovery.sol";

abstract contract AEDRecovery is ModuleBase, IAEDRecovery {
    using LibRecovery for AppStorage;
    
    function addGuardian(uint256 tokenId, address guardian) external override onlyTokenOwner(tokenId) {
        LibRecovery.addGuardian(tokenId, guardian);
    }
    
    function removeGuardian(uint256 tokenId, address guardian) external override onlyTokenOwner(tokenId) {
        LibRecovery.removeGuardian(tokenId, guardian);
    }
    
    function initiateRecovery(uint256 tokenId, address newOwner) external override {
        LibRecovery.initiateRecovery(tokenId, newOwner);
    }
    
    function confirmRecovery(uint256 tokenId) external override {
        LibRecovery.confirmRecovery(tokenId);
    }
    
    function cancelRecovery(uint256 tokenId) external override {
        LibRecovery.cancelRecovery(tokenId);
    }
    
    function executeRecovery(uint256 tokenId) external override {
        LibRecovery.executeRecovery(tokenId);
    }
    
    function getGuardians(uint256 tokenId) external view override returns (address[] memory) {
        return LibRecovery.getGuardians(tokenId);
    }
    
    function getRecoveryInfo(uint256 tokenId) external view override returns (
        address newOwner,
        uint256 confirmations,
        uint256 requiredConfirmations,
        uint256 deadline,
        bool isActive
    ) {
        return LibRecovery.getRecoveryInfo(tokenId);
    }
    
    function isGuardian(uint256 tokenId, address account) external view override returns (bool) {
        return LibRecovery.isGuardian(tokenId, account);
    }
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDRecovery");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDRecovery";
    }
}
