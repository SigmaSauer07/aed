// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";

library LibEvolution {
    using LibAppStorage for AppStorage;

    event FragmentEarned(uint256 indexed tokenId, string fragmentType, uint256 timestamp);
    event EvolutionLevelUp(uint256 indexed tokenId, uint256 newLevel);

    /**
     * @dev Award a fragment to a token
     * @param tokenId The token receiving the fragment
     * @param fragmentType The type of fragment (e.g., "first_domain", "vision_pioneer")
     * @param eventHash Hash of the event that triggered this fragment
     */
    function awardFragment(uint256 tokenId, string memory fragmentType, bytes32 eventHash) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        require(s.owners[tokenId] != address(0), "Token does not exist");

        // Check if fragment already awarded (some fragments are one-time only)
        if (_isOneTimeFragment(fragmentType)) {
            require(!s.hasFragment[tokenId][fragmentType], "Fragment already earned");
        }

        // Create and store fragment
        Fragment memory fragment = Fragment({
            fragmentType: fragmentType,
            earnedAt: block.timestamp,
            eventHash: eventHash
        });

        s.tokenFragments[tokenId].push(fragment);
        s.hasFragment[tokenId][fragmentType] = true;

        // Update evolution level (1 level per 5 fragments by default)
        uint256 oldLevel = s.evolutionLevels[tokenId];
        uint256 newLevel = s.tokenFragments[tokenId].length / 5;

        if (newLevel > oldLevel) {
            s.evolutionLevels[tokenId] = newLevel;
            emit EvolutionLevelUp(tokenId, newLevel);
        }

        emit FragmentEarned(tokenId, fragmentType, block.timestamp);
    }

    /**
     * @dev Award multiple fragments at once (batch operation)
     */
    function awardFragments(uint256 tokenId, string[] memory fragmentTypes, bytes32 eventHash) internal {
        for (uint256 i = 0; i < fragmentTypes.length; i++) {
            awardFragment(tokenId, fragmentTypes[i], eventHash);
        }
    }

    /**
     * @dev Get all fragments for a token
     */
    function getTokenFragments(uint256 tokenId) internal view returns (Fragment[] memory) {
        return LibAppStorage.appStorage().tokenFragments[tokenId];
    }

    /**
     * @dev Get evolution level for a token
     */
    function getEvolutionLevel(uint256 tokenId) internal view returns (uint256) {
        return LibAppStorage.appStorage().evolutionLevels[tokenId];
    }

    /**
     * @dev Check if token has a specific fragment
     */
    function hasFragment(uint256 tokenId, string memory fragmentType) internal view returns (bool) {
        return LibAppStorage.appStorage().hasFragment[tokenId][fragmentType];
    }

    /**
     * @dev Get total fragment count for a token
     */
    function getFragmentCount(uint256 tokenId) internal view returns (uint256) {
        return LibAppStorage.appStorage().tokenFragments[tokenId].length;
    }

    /**
     * @dev Award achievement fragments based on actions
     */
    function awardAchievementFragment(uint256 tokenId, string memory achievementType) internal {
        bytes32 eventHash = keccak256(abi.encodePacked(tokenId, achievementType, block.timestamp));
        awardFragment(tokenId, achievementType, eventHash);
    }

    /**
     * @dev Check if fragment type is one-time only
     */
    function _isOneTimeFragment(string memory fragmentType) private pure returns (bool) {
        bytes32 typeHash = keccak256(bytes(fragmentType));

        // One-time fragments
        if (typeHash == keccak256(bytes("first_domain"))) return true;
        if (typeHash == keccak256(bytes("early_adopter"))) return true;
        if (typeHash == keccak256(bytes("genesis"))) return true;

        // Repeatable fragments (e.g., "subdomain_creator" can be earned multiple times)
        return false;
    }

    /**
     * @dev Get fragment color for rendering
     */
    function getFragmentColor(string memory fragmentType) internal pure returns (string memory) {
        bytes32 typeHash = keccak256(bytes(fragmentType));

        if (typeHash == keccak256(bytes("first_domain"))) return "#39FF14"; // Neon green
        if (typeHash == keccak256(bytes("subdomain_creator"))) return "#00F6FF"; // Cyan
        if (typeHash == keccak256(bytes("vision_pioneer"))) return "#FF2E92"; // Pink
        if (typeHash == keccak256(bytes("communication_expert"))) return "#FF5A36"; // Orange
        if (typeHash == keccak256(bytes("early_adopter"))) return "#FFD700"; // Gold
        if (typeHash == keccak256(bytes("bridge_master"))) return "#9D4EDD"; // Purple

        return "#FFFFFF"; // Default white
    }

    /**
     * @dev Get fragment icon/emoji for rendering
     */
    function getFragmentIcon(string memory fragmentType) internal pure returns (string memory) {
        bytes32 typeHash = keccak256(bytes(fragmentType));

        if (typeHash == keccak256(bytes("first_domain"))) return "1";
        if (typeHash == keccak256(bytes("subdomain_creator"))) return "S";
        if (typeHash == keccak256(bytes("vision_pioneer"))) return "V";
        if (typeHash == keccak256(bytes("communication_expert"))) return "C";
        if (typeHash == keccak256(bytes("early_adopter"))) return "E";
        if (typeHash == keccak256(bytes("bridge_master"))) return "B";

        return "F"; // Default fragment
    }
}
