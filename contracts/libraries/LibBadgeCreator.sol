// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";
import "./LibEvolution.sol";
import "./LibPayment.sol";
import "../core/AEDConstants.sol";

/**
 * @title LibBadgeCreator
 * @dev Handles badge (AI subdomain) creation and AI capability management
 */
library LibBadgeCreator {
    using LibAppStorage for AppStorage;

    event BadgeCreated(uint256 indexed tokenId, string indexed parentDomain, string modelType);
    event CapabilityUnlocked(uint256 indexed tokenId, string capability);

    /**
     * @dev Create AI subdomain (badge) for a specific AI model
     * @param label Badge name (e.g., "claude", "echo")
     * @param parentDomain Parent domain that owns this badge
     * @param modelType AI model identifier (e.g., "claude-3.5-sonnet")
     */
    function createAISubdomain(
        string memory label,
        string memory parentDomain,
        string memory modelType
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.domainExists[parentDomain], "Parent domain not found");
        uint256 parentTokenId = s.domainToTokenId[parentDomain];
        require(s.owners[parentTokenId] == msg.sender, "Not parent owner");
        
        // Count existing badges and enforce MAX_BADGES limit
        uint256 badgeCount = _countBadgesUnderParent(s, parentDomain);
        require(badgeCount < AEDConstants(address(this)).MAX_BADGES(), "Max badges reached");
        
        // Create badge name
        string memory badgeName = string(abi.encodePacked(label, ".", parentDomain));
        require(!s.domainExists[badgeName], "Badge already exists");
        
        uint256 tokenId = s.nextTokenId++;
        
        // Store badge data
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        s.domainToTokenId[badgeName] = tokenId;
        s.tokenIdToDomain[tokenId] = badgeName;
        s.domainExists[badgeName] = true;
        s.userDomains[msg.sender].push(badgeName);
        
        // Mark as AI subdomain
        s.aiModelType[tokenId] = modelType;
        s.isAISubdomain[tokenId] = true;
        
        // Initialize domain struct
        s.domains[tokenId] = Domain({
            name: label,
            tld: _extractTLD(parentDomain),
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: true,
            owner: msg.sender
        });
        
        // Award first badge fragment to parent
        bytes32 eventHash = keccak256(abi.encodePacked("first_badge", parentTokenId, tokenId, block.timestamp));
        LibEvolution.awardFragment(parentTokenId, "first_badge", eventHash);
        
        emit BadgeCreated(tokenId, parentDomain, modelType);
        return tokenId;
    }

    /**
     * @dev Purchase AI capability for badge
     */
    function purchaseAICapability(uint256 tokenId, string memory capabilityType) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.owners[tokenId] == msg.sender, "Not badge owner");
        require(s.isAISubdomain[tokenId], "Not an AI badge");
        
        bytes32 capHash = keccak256(bytes(capabilityType));
        require(!s.aiCapabilities[tokenId][capabilityType], "Already unlocked");
        
        // Unlock capability
        s.aiCapabilities[tokenId][capabilityType] = true;
        
        // Award fragment for capability
        bytes32 eventHash = keccak256(abi.encodePacked("capability", tokenId, capabilityType, block.timestamp));
        
        if (capHash == keccak256("ai_vision")) {
            LibEvolution.awardFragment(tokenId, "vision_pioneer", eventHash);
        } else if (capHash == keccak256("ai_communication")) {
            LibEvolution.awardFragment(tokenId, "communication_expert", eventHash);
        } else if (capHash == keccak256("ai_memory")) {
            LibEvolution.awardFragment(tokenId, "memory_keeper", eventHash);
        } else if (capHash == keccak256("ai_reasoning")) {
            LibEvolution.awardFragment(tokenId, "reasoning_master", eventHash);
        }
        
        emit CapabilityUnlocked(tokenId, capabilityType);
    }

    /**
     * @dev Calculate badge creation fee (exponential per parent domain)
     * Returns USDC amount (6 decimals)
     */
    function calculateAISubdomainFee(uint256 parentTokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        string memory parentDomain = s.tokenIdToDomain[parentTokenId];
        
        uint256 badgeCount = _countBadgesUnderParent(s, parentDomain);
        
        // Get base fee (admin adjustable, defaults to $1.00)
        uint256 baseFee = s.fees["badgeBase"];
        if (baseFee == 0) {
            baseFee = AEDConstants(address(this)).DEFAULT_BADGE_FEE();
        }
        
        // Price: baseFee * 2^n
        if (badgeCount == 0) return baseFee;
        return baseFee * (2 ** badgeCount);
    }

    /**
     * @dev Calculate capability unlock fee (exponential per badge)
     * Returns USDC amount (6 decimals)
     */
    function calculateCapabilityFee(uint256 tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        uint256 capCount = 0;
        string[4] memory caps = ["ai_vision", "ai_communication", "ai_memory", "ai_reasoning"];
        
        for (uint256 i = 0; i < caps.length; i++) {
            if (s.aiCapabilities[tokenId][caps[i]]) capCount++;
        }
        
        // Get base fee (admin adjustable, defaults to $1.00)
        uint256 baseFee = s.fees["capabilityBase"];
        if (baseFee == 0) {
            baseFee = AEDConstants(address(this)).DEFAULT_CAPABILITY_FEE();
        }
        
        // Price: baseFee * 2^n
        if (capCount == 0) return baseFee;
        return baseFee * (2 ** capCount);
    }
    
    /**
     * @dev Count badges under a specific parent domain
     */
    function _countBadgesUnderParent(AppStorage storage s, string memory parentDomain) private view returns (uint256) {
        uint256 badgeCount = 0;
        string[] memory userDomains = s.userDomains[msg.sender];
        
        // Count existing badges under this parent
        for (uint256 i = 0; i < userDomains.length; i++) {
            uint256 tid = s.domainToTokenId[userDomains[i]];
            if (s.isAISubdomain[tid] && _isChildOf(userDomains[i], parentDomain)) {
                badgeCount++;
            }
        }
        
        return badgeCount;
    }

    /**
     * @dev Check if badge has capability
     */
    function hasAICapability(uint256 tokenId, string memory capabilityType) internal view returns (bool) {
        return LibAppStorage.appStorage().aiCapabilities[tokenId][capabilityType];
    }

    /**
     * @dev Get AI model type for badge
     */
    function getModelType(uint256 tokenId) internal view returns (string memory) {
        return LibAppStorage.appStorage().aiModelType[tokenId];
    }

    /**
     * @dev Check if token is AI subdomain
     */
    function isAISubdomain(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.appStorage().isAISubdomain[tokenId];
    }

    /**
     * @dev Get badge token ID for model under parent
     */
    function getAISubdomain(string memory parentDomain, string memory modelType) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        string[] memory userDomains = s.userDomains[msg.sender];
        
        for (uint256 i = 0; i < userDomains.length; i++) {
            uint256 tid = s.domainToTokenId[userDomains[i]];
            if (s.isAISubdomain[tid] && 
                _isChildOf(userDomains[i], parentDomain) &&
                keccak256(bytes(s.aiModelType[tid])) == keccak256(bytes(modelType))) {
                return tid;
            }
        }
        
        return 0;
    }

    function _extractTLD(string memory domain) private pure returns (string memory) {
        bytes memory domainBytes = bytes(domain);
        for (uint256 i = domainBytes.length; i > 0; i--) {
            if (domainBytes[i - 1] == 0x2E) {
                bytes memory tld = new bytes(domainBytes.length - i);
                for (uint256 j = 0; j < tld.length; j++) {
                    tld[j] = domainBytes[i + j];
                }
                return string(tld);
            }
        }
        return domain;
    }

    function _isChildOf(string memory child, string memory parent) private pure returns (bool) {
        bytes memory childBytes = bytes(child);
        bytes memory parentBytes = bytes(parent);
        
        if (childBytes.length <= parentBytes.length) return false;
        
        uint256 offset = childBytes.length - parentBytes.length - 1;
        if (childBytes[offset] != 0x2E) return false;
        
        for (uint256 i = 0; i < parentBytes.length; i++) {
            if (childBytes[offset + 1 + i] != parentBytes[i]) return false;
        }
        
        return true;
    }
}
