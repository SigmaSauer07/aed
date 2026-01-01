// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";

/**
 * @title LibEvolution
 * @dev Fragment system and evolution mechanics
 */
library LibEvolution {
    using LibAppStorage for AppStorage;

    event FragmentEarned(uint256 indexed tokenId, string fragmentType, uint256 timestamp);
    event EvolutionLevelUp(uint256 indexed tokenId, uint256 newLevel);

    /**
     * @dev Award fragment to token (domain, subdomain, or badge)
     */
    function awardFragment(uint256 tokenId, string memory fragmentType, bytes32 eventHash) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        require(s.owners[tokenId] != address(0), "Token does not exist");

        // Check if one-time fragment already awarded
        if (_isOneTimeFragment(fragmentType)) {
            require(!s.hasFragment[tokenId][fragmentType], "Fragment already earned");
        }

        // Store fragment
        s.tokenFragments[tokenId].push(Fragment({
            fragmentType: fragmentType,
            earnedAt: block.timestamp,
            eventHash: eventHash
        }));

        s.hasFragment[tokenId][fragmentType] = true;

        // Update evolution level (1 level per 5 fragments)
        uint256 oldLevel = s.evolutionLevels[tokenId];
        uint256 newLevel = s.tokenFragments[tokenId].length / 5;

        if (newLevel > oldLevel) {
            s.evolutionLevels[tokenId] = newLevel;
            emit EvolutionLevelUp(tokenId, newLevel);
        }

        emit FragmentEarned(tokenId, fragmentType, block.timestamp);
    }

    /**
     * @dev Get all fragments for token
     */
    function getTokenFragments(uint256 tokenId) internal view returns (Fragment[] memory) {
        return LibAppStorage.appStorage().tokenFragments[tokenId];
    }

    /**
     * @dev Get evolution level
     */
    function getEvolutionLevel(uint256 tokenId) internal view returns (uint256) {
        return LibAppStorage.appStorage().evolutionLevels[tokenId];
    }

    /**
     * @dev Check if token has specific fragment
     */
    function hasFragment(uint256 tokenId, string memory fragmentType) internal view returns (bool) {
        return LibAppStorage.appStorage().hasFragment[tokenId][fragmentType];
    }

    /**
     * @dev Get fragment count
     */
    function getFragmentCount(uint256 tokenId) internal view returns (uint256) {
        return LibAppStorage.appStorage().tokenFragments[tokenId].length;
    }

    /**
     * @dev Get frame color based on evolution level
     */
    function getFrameColor(uint256 level) internal pure returns (string memory) {
        if (level == 0) return "#39FF14";      // Neon green
        if (level < 5) return "#00F6FF";       // Cyan
        if (level < 10) return "#FF2E92";      // Pink
        if (level < 15) return "#9D4EDD";      // Purple
        return "#FFD700";                      // Gold
    }

    /**
     * @dev Get fragment visual properties
     */
    function getFragmentVisual(string memory fragmentType) internal pure returns (string memory color, string memory icon) {
        bytes32 typeHash = keccak256(bytes(fragmentType));

        if (typeHash == keccak256("first_domain")) return ("#39FF14", "1");
        if (typeHash == keccak256("first_badge")) return ("#9D4EDD", "B");
        if (typeHash == keccak256("subdomain_creator")) return ("#00F6FF", "S");
        if (typeHash == keccak256("vision_pioneer")) return ("#FF2E92", "V");
        if (typeHash == keccak256("communication_expert")) return ("#FF5A36", "C");
        if (typeHash == keccak256("memory_keeper")) return ("#FFD700", "M");
        if (typeHash == keccak256("reasoning_master")) return ("#9D4EDD", "R");
        if (typeHash == keccak256("bridge_master")) return ("#9D4EDD", "⟷");
        if (typeHash == keccak256("early_adopter")) return ("#FFD700", "E");

        return ("#FFFFFF", "F"); // Default
    }

    /**
     * @dev Check if fragment is one-time only
     */
    function _isOneTimeFragment(string memory fragmentType) private pure returns (bool) {
        bytes32 typeHash = keccak256(bytes(fragmentType));

        // One-time fragments
        if (typeHash == keccak256("first_domain")) return true;
        if (typeHash == keccak256("first_badge")) return true;
        if (typeHash == keccak256("early_adopter")) return true;
        if (typeHash == keccak256("genesis")) return true;

        // Repeatable fragments
        return false;
    }
}
