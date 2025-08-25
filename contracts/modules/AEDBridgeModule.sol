// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "../libraries/LibAppStorage.sol";
import "../interfaces/modules/IAEDBridge.sol";
import "./base/ModuleBase.sol";

/// @title AED Bridge Module
/// @dev Standalone bridge module for the modular UUPS system
contract AEDBridgeModule is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IAEDBridge,
    AEDConstants,
    ModuleBase
{
    using LibAppStorage for AppStorage;
    
    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }
    
    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) 
        internal 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        override 
    {}
    
    // Module interface
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AED_BRIDGE");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AED Bridge";
    }
    
    // Bridge functions
    function bridgeDomain(uint256 tokenId, string calldata destination) external override {
        // Implementation for bridging domain to another chain
        require(LibAppStorage.appStorage().owners[tokenId] == msg.sender, "Not token owner");
        // Placeholder implementation - would need actual bridge logic
        emit DomainBridgeRequested(tokenId, 0); // 0 for placeholder chainId
    }
    
    function claimBridgedDomain(uint256 tokenId, bytes32 bridgeHash, bytes calldata signature) external override {
        // Implementation for claiming bridged domain
        // Placeholder implementation - would need actual bridge logic
    }
    
    function getBridgeInfo(uint256 tokenId) external view override returns (
        uint256 destChainId,
        bytes32 bridgeHash,
        uint256 timestamp,
        bool isBridgedOut
    ) {
        BridgeInfo memory info = LibAppStorage.appStorage().bridgedDomains[tokenId];
        return (info.chainId, bytes32(0), info.bridgedAt, info.isBridgedOut);
    }
    
    function isBridged(uint256 tokenId) external view override returns (bool) {
        return LibAppStorage.appStorage().bridgedDomains[tokenId].isBridgedOut;
    }
    
    function isSupportedChain(uint256 chainId) external view override returns (bool) {
        return LibAppStorage.appStorage().bridgeConfigs[chainId].enabled;
    }
} 