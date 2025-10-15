// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";

library LibBridge {
    using LibAppStorage for AppStorage;
    
    event DomainBridged(uint256 indexed tokenId, string indexed domain, uint256 indexed chainId);
    event DomainUnbridged(uint256 indexed tokenId, string indexed domain, uint256 indexed chainId);
    event BridgeConfigured(uint256 indexed chainId, address indexed bridgeAddress, bool enabled);
    
    /**
     * @dev Bridges a domain to another chain
     * @param tokenId The token ID to bridge
     * @param targetChainId The target chain ID
     */
    function bridgeDomain(uint256 tokenId, uint256 targetChainId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Verify domain exists and caller owns it
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        require(s.bridgeConfigs[targetChainId].enabled, "Bridge not enabled for chain");
        
        string memory domain = s.tokenIdToDomain[tokenId];
        
        // Mark as bridged
        s.bridgedDomains[tokenId] = BridgeInfo({
            chainId: targetChainId,
            bridgeAddress: s.bridgeConfigs[targetChainId].bridgeAddress,
            bridgedAt: block.timestamp,
            isBridgedOut: true
        });
        
        emit DomainBridged(tokenId, domain, targetChainId);
    }
    
    /**
     * @dev Unbridges a domain back to current chain
     * @param tokenId The token ID to unbridge
     */
    function unbridgeDomain(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Verify domain is bridged
        require(s.bridgedDomains[tokenId].isBridgedOut, "Domain not bridged");
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        
        string memory domain = s.tokenIdToDomain[tokenId];
        uint256 chainId = s.bridgedDomains[tokenId].chainId;
        
        // Clear bridge info
        delete s.bridgedDomains[tokenId];
        
        emit DomainUnbridged(tokenId, domain, chainId);
    }
    
    /**
     * @dev Configures bridge settings for a chain
     * @param chainId The chain ID
     * @param bridgeAddress The bridge contract address
     * @param enabled Whether the bridge is enabled
     */
    function configureBridge(
        uint256 chainId,
        address bridgeAddress,
        bool enabled
    ) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        s.bridgeConfigs[chainId] = BridgeConfig({
            bridgeAddress: bridgeAddress,
            enabled: enabled
        });
        
        emit BridgeConfigured(chainId, bridgeAddress, enabled);
    }
    
    /**
     * @dev Checks if a domain is bridged
     * @param tokenId The token ID to check
     * @return bridgedStatus True if domain is bridged
     */
    function isBridged(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.appStorage().bridgedDomains[tokenId].isBridgedOut;
    }
    
    /**
     * @dev Gets bridge information for a domain
     * @param tokenId The token ID
     * @return bridgeInfo The bridge information
     */
    function getBridgeInfo(uint256 tokenId) internal view returns (BridgeInfo memory) {
        return LibAppStorage.appStorage().bridgedDomains[tokenId];
    }
    
    /**
     * @dev Gets bridge configuration for a chain
     * @param chainId The chain ID
     * @return bridgeConfig The bridge configuration
     */
    function getBridgeConfig(uint256 chainId) internal view returns (BridgeConfig memory) {
        return LibAppStorage.appStorage().bridgeConfigs[chainId];
    }
    
    /**
     * @dev Checks if bridge is enabled for a chain
     * @param chainId The chain ID
     * @return enabled True if bridge is enabled
     */
    function isBridgeEnabled(uint256 chainId) internal view returns (bool) {
        return LibAppStorage.appStorage().bridgeConfigs[chainId].enabled;
    }
}
