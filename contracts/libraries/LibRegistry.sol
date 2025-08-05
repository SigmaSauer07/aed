// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";

/// @title Library for managing registry of addresses and their associated data.
/// @author SigmaSauer07 <https://github.com/SigmaSauer07>
/// @notice This library provides a simple way to store and retrieve data associated with an address in the registry.
library LibRegistry {
    using LibAppStorage for AppStorage;
    
    // Feature flags
    uint256 constant FEATURE_SUBDOMAINS = 1 << 0;
    uint256 constant FEATURE_METADATA = 1 << 1;
    uint256 constant FEATURE_REVERSE = 1 << 2;
    uint256 constant FEATURE_BRIDGE = 1 << 3;
    
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);
    event ExternalDomainLinked(string indexed externalDomain, uint256 indexed tokenId);
    event ExternalDomainUnlinked(string indexed externalDomain);
    
    function enableFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = LibAppStorage.s();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        
        s.domainFeatures[tokenId] |= feature;
        emit FeatureEnabled(tokenId, feature);
    }
    
    function disableFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = LibAppStorage.s();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        
        s.domainFeatures[tokenId] &= ~feature;
        emit FeatureDisabled(tokenId, feature);
    }
    
    function hasFeature(uint256 tokenId, uint256 feature) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.s();
        return (s.domainFeatures[tokenId] & feature) != 0;
    }
    
    function linkExternalDomain(string calldata externalDomain, uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.s();
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        require(s.futureUint256[keccak256(bytes(externalDomain))] == 0, "Already linked");
        
        // Charge BYO fee
        uint256 byoFee = s.enhancementPrices["byo"];
        require(msg.value >= byoFee, "Insufficient payment");
        
        s.futureUint256[keccak256(bytes(externalDomain))] = tokenId;
        s.totalRevenue += byoFee;
        payable(s.feeCollector).transfer(byoFee);
        
        // Enable subdomain feature for linked domain
        s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
        
        emit ExternalDomainLinked(externalDomain, tokenId);
        
        // Refund excess
        if (msg.value > byoFee) {
            payable(msg.sender).transfer(msg.value - byoFee);
        }
    }
    
    function unlinkExternalDomain(string calldata externalDomain) internal {
        AppStorage storage s = LibAppStorage.s();
        uint256 tokenId = s.futureUint256[keccak256(bytes(externalDomain))];
        require(tokenId != 0, "Domain not linked");
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        
        delete s.futureUint256[keccak256(bytes(externalDomain))];
        emit ExternalDomainUnlinked(externalDomain);
    }
    
    function getLinkedDomain(string calldata externalDomain) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.s();
        return s.futureUint256[keccak256(bytes(externalDomain))];
    }
}
