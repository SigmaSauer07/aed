// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibBadges {
    using LibAppStorage for AppStorage;
    using Strings for uint256;
    
    event BadgeAwarded(uint256 indexed tokenId, string indexed badgeType, bool isCapability);
    event EvolutionLevelUp(uint256 indexed tokenId, uint256 newLevel);
    
    /**
     * @dev Award a badge to a domain (decorative or capability)
     * @param tokenId The token to award badge to
     * @param badgeType Type of badge (e.g., "vision_pioneer", "subdomain_creator")
     * @param memoryData Additional data about the achievement
     * @param isCapability True if this unlocks AI capability, false if decorative
     */
    function awardBadge(
        uint256 tokenId,
        string memory badgeType,
        bytes memory memoryData,
        bool isCapability
    ) internal {
        require(LibAppStorage.tokenExists(tokenId), "Token does not exist");
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Check if badge already awarded (prevent duplicates)
        Badge[] storage badges = s.tokenBadges[tokenId];
        for (uint256 i = 0; i < badges.length; i++) {
            if (keccak256(bytes(badges[i].badgeType)) == keccak256(bytes(badgeType))) {
                revert("Badge already awarded");
            }
        }
        
        // Add badge
        s.tokenBadges[tokenId].push(Badge({
            badgeType: badgeType,
            awardedAt: block.timestamp,
            memoryData: memoryData,
            isCapability: isCapability
        }));
        
        // Increase evolution level (capabilities give more points)
        uint256 levelIncrease = isCapability ? 2 : 1;
        s.evolutionLevel[tokenId] += levelIncrease;
        
        emit BadgeAwarded(tokenId, badgeType, isCapability);
        emit EvolutionLevelUp(tokenId, s.evolutionLevel[tokenId]);
    }
    
    /**
     * @dev Award badge for subdomain creation (auto-triggered)
     */
    function awardSubdomainBadge(uint256 tokenId, uint256 subdomainCount) internal {
        if (subdomainCount == 1) {
            awardBadge(tokenId, "first_subdomain", abi.encodePacked(subdomainCount), false);
        } else if (subdomainCount == 5) {
            awardBadge(tokenId, "subdomain_veteran", abi.encodePacked(subdomainCount), false);
        } else if (subdomainCount == 10) {
            awardBadge(tokenId, "subdomain_master", abi.encodePacked(subdomainCount), false);
        }
    }
    
    /**
     * @dev Award AI capability badge (unlocks actual functionality)
     */
    function awardAICapabilityBadge(
        uint256 tokenId,
        string memory capabilityType
    ) internal {
        bytes memory data = abi.encodePacked("capability:", capabilityType);
        awardBadge(tokenId, capabilityType, data, true);
    }
    
    /**
     * @dev Check if token has a specific badge
     */
    function hasBadge(uint256 tokenId, string memory badgeType) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        Badge[] storage badges = s.tokenBadges[tokenId];
        
        for (uint256 i = 0; i < badges.length; i++) {
            if (keccak256(bytes(badges[i].badgeType)) == keccak256(bytes(badgeType))) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Check if token has AI capability badge
     */
    function hasCapability(uint256 tokenId, string memory capabilityType) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        Badge[] storage badges = s.tokenBadges[tokenId];
        
        for (uint256 i = 0; i < badges.length; i++) {
            if (badges[i].isCapability && 
                keccak256(bytes(badges[i].badgeType)) == keccak256(bytes(capabilityType))) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Get all badges for a token
     */
    function getTokenBadges(uint256 tokenId) internal view returns (Badge[] memory) {
        return LibAppStorage.appStorage().tokenBadges[tokenId];
    }
    
    /**
     * @dev Get evolution level for a token
     */
    function getEvolutionLevel(uint256 tokenId) internal view returns (uint256) {
        return LibAppStorage.appStorage().evolutionLevel[tokenId];
    }
    
    /**
     * @dev Generate SVG layers for badges (max 5 displayed)
     */
    function getBadgeSVG(uint256 tokenId) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        Badge[] memory badges = s.tokenBadges[tokenId];
        
        if (badges.length == 0) return "";
        
        string memory svg;
        uint256 displayCount = badges.length > 5 ? 5 : badges.length;
        
        for (uint256 i = 0; i < displayCount; i++) {
            svg = string(abi.encodePacked(
                svg,
                _generateBadgeIcon(badges[i].badgeType, badges[i].isCapability, i)
            ));
        }
        
        // Add badge count indicator if more than 5
        if (badges.length > 5) {
            svg = string(abi.encodePacked(
                svg,
                '<text x="380" y="370" font-family="monospace" font-size="10" text-anchor="end" fill="#39FF14">+',
                (badges.length - 5).toString(),
                '</text>'
            ));
        }
        
        return svg;
    }
    
    /**
     * @dev Generate individual badge icon SVG
     */
    function _generateBadgeIcon(
        string memory badgeType, 
        bool isCapability,
        uint256 index
    ) private pure returns (string memory) {
        uint256 x = 60 + (index * 70);
        uint256 y = 350;
        
        bytes32 badgeHash = keccak256(bytes(badgeType));
        
        // AI Capability badges (metallic look)
        if (isCapability) {
            if (badgeHash == keccak256("ai_vision")) {
                return _createCapabilityBadge(x, y, "👁️", "#00F6FF");
            } else if (badgeHash == keccak256("ai_communication")) {
                return _createCapabilityBadge(x, y, "💬", "#FF2E92");
            } else if (badgeHash == keccak256("ai_memory")) {
                return _createCapabilityBadge(x, y, "🧠", "#9D4EDD");
            } else if (badgeHash == keccak256("ai_reasoning")) {
                return _createCapabilityBadge(x, y, "⚡", "#FFD700");
            }
            // Default capability badge
            return _createCapabilityBadge(x, y, "⚙️", "#C0C0C0");
        }
        
        // Decorative badges
        if (badgeHash == keccak256("first_subdomain")) {
            return _createDecorativeBadge(x, y, "+", "#39FF14");
        } else if (badgeHash == keccak256("subdomain_veteran")) {
            return _createDecorativeBadge(x, y, "✦", "#00F6FF");
        } else if (badgeHash == keccak256("subdomain_master")) {
            return _createDecorativeBadge(x, y, "★", "#FFD700");
        }
        
        // Default decorative badge
        return _createDecorativeBadge(x, y, "•", "#FF2E92");
    }
    
    /**
     * @dev Create capability badge (metallic hexagon)
     */
    function _createCapabilityBadge(
        uint256 x,
        uint256 y,
        string memory icon,
        string memory color
    ) private pure returns (string memory) {
        return string(abi.encodePacked(
            '<g transform="translate(', x.toString(), ',', y.toString(), ')">',
            // Hexagon shape
            '<polygon points="-12,0 -6,-10 6,-10 12,0 6,10 -6,10" fill="', color, '" opacity="0.95" stroke="#FFFFFF" stroke-width="1"/>',
            // Metallic gradient effect
            '<polygon points="-12,0 -6,-10 6,-10 12,0 6,10 -6,10" fill="url(#metalGrad)" opacity="0.3"/>',
            // Icon
            '<text x="0" y="5" font-size="12" text-anchor="middle" fill="#0A0A0A">', icon, '</text>',
            '</g>'
        ));
    }
    
    /**
     * @dev Create decorative badge (simple circle)
     */
    function _createDecorativeBadge(
        uint256 x,
        uint256 y,
        string memory icon,
        string memory color
    ) private pure returns (string memory) {
        return string(abi.encodePacked(
            '<g transform="translate(', x.toString(), ',', y.toString(), ')">',
            '<circle r="15" fill="', color, '" opacity="0.9" stroke="#FFFFFF" stroke-width="1"/>',
            '<text x="0" y="5" font-size="14" text-anchor="middle" fill="#0A0A0A">', icon, '</text>',
            '</g>'
        ));
    }
}
