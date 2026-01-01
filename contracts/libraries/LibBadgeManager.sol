// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";

/**
 * @title LibBadgeManager
 * @dev Manages badge lifecycle: burn, transfer locks, capability removal
 */
library LibBadgeManager {
    using LibAppStorage for AppStorage;

    event BadgeBurned(uint256 indexed tokenId, address indexed owner);
    event BadgeTransferLocked(uint256 indexed tokenId);
    event BadgeTransferUnlocked(uint256 indexed tokenId);
    event CapabilityRemoved(uint256 indexed tokenId, string capability);

    /**
     * @dev Burn a badge (AI subdomain)
     */
    function burnBadge(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.owners[tokenId] == msg.sender, "Not badge owner");
        require(s.isAISubdomain[tokenId], "Not a badge");
        require(!s.badgeTransferLocked[tokenId], "Badge locked while synced");
        
        address owner = s.owners[tokenId];
        string memory badgeName = s.tokenIdToDomain[tokenId];
        
        // Clear ownership
        delete s.owners[tokenId];
        s.balances[owner]--;
        
        // Clear mappings
        delete s.domainToTokenId[badgeName];
        delete s.tokenIdToDomain[tokenId];
        delete s.domainExists[badgeName];
        delete s.domains[tokenId];
        
        // Clear AI-specific data
        delete s.aiModelType[tokenId];
        delete s.isAISubdomain[tokenId];
        delete s.badgeTransferLocked[tokenId];
        
        // Clear capabilities
        string[4] memory caps = ["ai_vision", "ai_communication", "ai_memory", "ai_reasoning"];
        for (uint256 i = 0; i < caps.length; i++) {
            delete s.aiCapabilities[tokenId][caps[i]];
        }
        
        // Clear fragments
        delete s.tokenFragments[tokenId];
        delete s.evolutionLevels[tokenId];
        
        // Remove from user domains
        _removeFromUserDomains(owner, badgeName);
        
        emit BadgeBurned(tokenId, owner);
    }

    /**
     * @dev Lock badge transfer while AI is synced
     */
    function lockBadgeTransfer(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.owners[tokenId] == msg.sender, "Not badge owner");
        require(s.isAISubdomain[tokenId], "Not a badge");
        
        s.badgeTransferLocked[tokenId] = true;
        emit BadgeTransferLocked(tokenId);
    }

    /**
     * @dev Unlock badge transfer after AI disconnect
     */
    function unlockBadgeTransfer(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.owners[tokenId] == msg.sender, "Not badge owner");
        require(s.isAISubdomain[tokenId], "Not a badge");
        
        s.badgeTransferLocked[tokenId] = false;
        emit BadgeTransferUnlocked(tokenId);
    }

    /**
     * @dev Check if badge transfer is locked
     */
    function isBadgeTransferLocked(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.appStorage().badgeTransferLocked[tokenId];
    }

    /**
     * @dev Remove capability from badge (admin only or paid downgrade)
     */
    function removeCapability(uint256 tokenId, string memory capabilityType) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.isAISubdomain[tokenId], "Not a badge");
        require(s.aiCapabilities[tokenId][capabilityType], "Capability not active");
        
        s.aiCapabilities[tokenId][capabilityType] = false;
        emit CapabilityRemoved(tokenId, capabilityType);
    }

    /**
     * @dev Get all active capabilities for badge
     */
    function getActiveCapabilities(uint256 tokenId) internal view returns (string[] memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        string[4] memory caps = ["ai_vision", "ai_communication", "ai_memory", "ai_reasoning"];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < caps.length; i++) {
            if (s.aiCapabilities[tokenId][caps[i]]) activeCount++;
        }
        
        string[] memory active = new string[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < caps.length; i++) {
            if (s.aiCapabilities[tokenId][caps[i]]) {
                active[index++] = caps[i];
            }
        }
        
        return active;
    }

    /**
     * @dev Count badges owned by user under specific parent
     */
    function getBadgeCount(address owner, string memory parentDomain) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        string[] memory userDomains = s.userDomains[owner];
        
        uint256 count = 0;
        for (uint256 i = 0; i < userDomains.length; i++) {
            uint256 tid = s.domainToTokenId[userDomains[i]];
            if (s.isAISubdomain[tid] && _isChildOf(userDomains[i], parentDomain)) {
                count++;
            }
        }
        
        return count;
    }

    function _removeFromUserDomains(address user, string memory domain) private {
        AppStorage storage s = LibAppStorage.appStorage();
        string[] storage userDomains = s.userDomains[user];
        
        for (uint256 i = 0; i < userDomains.length; i++) {
            if (keccak256(bytes(userDomains[i])) == keccak256(bytes(domain))) {
                userDomains[i] = userDomains[userDomains.length - 1];
                userDomains.pop();
                break;
            }
        }
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
