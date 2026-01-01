// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";
import "./LibEvolution.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title LibSVG
 * @dev Generates evolved SVG frames with fragment overlays
 */
library LibSVG {
    using LibAppStorage for AppStorage;
    using Strings for uint256;

    /**
     * @dev Generate complete SVG with evolution frame and fragments
     * @param tokenId Token to render
     * @param customImage User-set image URI (or empty)
     * @param isAI Whether token is AI badge
     */
    function generateSVG(
        uint256 tokenId,
        string memory customImage,
        bool isAI
    ) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        uint256 level = s.evolutionLevels[tokenId];
        Fragment[] memory fragments = s.tokenFragments[tokenId];
        string memory domain = s.tokenIdToDomain[tokenId];
        
        string memory baseImage = bytes(customImage).length > 0 
            ? customImage 
            : (s.domains[tokenId].isSubdomain 
                ? "ipfs://bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png"
                : "ipfs://bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png");
        
        return string(abi.encodePacked(
            '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
            _generateDefs(),
            '<image href="', baseImage, '" x="0" y="0" width="400" height="400"/>',
            _generateFrame(level),
            _generateDomainText(domain, isAI),
            _generateLevelIndicator(level),
            isAI ? _generateAIBadge(s.aiModelType[tokenId]) : '',
            _generateFragments(fragments, level),
            '</svg>'
        ));
    }

    function _generateDefs() private pure returns (string memory) {
        return string(abi.encodePacked(
            '<defs>',
            '<filter id="glow"><feGaussianBlur stdDeviation="3" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
            '<linearGradient id="metalGrad" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.3"/>',
            '<stop offset="50%" stop-color="#FFFFFF" stop-opacity="0.1"/>',
            '<stop offset="100%" stop-color="#000000" stop-opacity="0.2"/>',
            '</linearGradient>',
            '</defs>'
        ));
    }

    function _generateFrame(uint256 level) private pure returns (string memory) {
        string memory color = LibEvolution.getFrameColor(level);
        uint256 width = 3 + (level / 2);
        
        if (level == 0) {
            return string(abi.encodePacked(
                '<rect x="20" y="20" width="360" height="360" rx="20" fill="none" stroke="', color, '" stroke-width="', width.toString(), '"/>'
            ));
        } else if (level < 5) {
            return string(abi.encodePacked(
                '<rect x="20" y="20" width="360" height="360" rx="25" fill="none" stroke="', color, '" stroke-width="', width.toString(), '" filter="url(#glow)"/>',
                '<rect x="25" y="25" width="350" height="350" rx="20" fill="none" stroke="', color, '" stroke-width="1" opacity="0.5"/>'
            ));
        } else if (level < 10) {
            return string(abi.encodePacked(
                '<rect x="15" y="15" width="370" height="370" rx="30" fill="none" stroke="', color, '" stroke-width="', width.toString(), '" filter="url(#glow)"/>',
                '<rect x="20" y="20" width="360" height="360" rx="25" fill="none" stroke="', color, '" stroke-width="2" opacity="0.7"/>',
                '<path d="M20,20 L80,20 L20,80 Z" fill="', color, '" opacity="0.3"/>'
            ));
        } else {
            return string(abi.encodePacked(
                '<rect x="10" y="10" width="380" height="380" rx="35" fill="none" stroke="', color, '" stroke-width="', width.toString(), '" filter="url(#glow)"/>',
                '<rect x="15" y="15" width="370" height="370" rx="30" fill="none" stroke="', color, '" stroke-width="3" opacity="0.8"/>',
                '<rect x="20" y="20" width="360" height="360" rx="25" fill="none" stroke="#FFD700" stroke-width="1" opacity="0.5"/>',
                '<path d="M10,10 L100,10 L10,100 Z" fill="', color, '" opacity="0.4"/>',
                '<path d="M390,390 L300,390 L390,300 Z" fill="', color, '" opacity="0.4"/>',
                '<circle cx="200" cy="200" r="180" fill="none" stroke="', color, '" stroke-width="1" stroke-dasharray="15,10" opacity="0.3"/>'
            ));
        }
    }

    function _generateDomainText(string memory domain, bool isAI) private pure returns (string memory) {
        string memory truncated = _truncateString(domain, 25);
        
        return string(abi.encodePacked(
            '<rect x="50" y="180" width="300" height="70" rx="15" fill="rgba(10,10,10,0.85)" stroke="#39FF14" stroke-width="2"/>',
            '<text x="200" y="215" font-family="Orbitron,monospace" font-size="18" font-weight="bold" text-anchor="middle" fill="#39FF14">',
            truncated,
            '</text>',
            '<text x="200" y="235" font-family="Orbitron,monospace" font-size="12" text-anchor="middle" fill="#00F6FF">',
            isAI ? 'AI Badge' : 'Domain',
            '</text>'
        ));
    }

    function _generateLevelIndicator(uint256 level) private pure returns (string memory) {
        if (level == 0) return '';
        
        string memory color = LibEvolution.getFrameColor(level);
        
        return string(abi.encodePacked(
            '<g transform="translate(350, 50)">',
            '<circle r="25" fill="#0A0A0A" stroke="', color, '" stroke-width="2" filter="url(#glow)"/>',
            '<text y="8" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="', color, '">',
            level.toString(),
            '</text>',
            '<text y="18" font-family="Arial" font-size="8" text-anchor="middle" fill="', color, '">LVL</text>',
            '</g>'
        ));
    }

    function _generateAIBadge(string memory modelType) private pure returns (string memory) {
        string memory truncated = _truncateString(modelType, 12);
        
        return string(abi.encodePacked(
            '<g transform="translate(50, 50)">',
            '<circle r="25" fill="#9D4EDD" opacity="0.9" stroke="#FFFFFF" stroke-width="2"/>',
            '<text x="0" y="6" font-size="20" text-anchor="middle" fill="#FFFFFF">🤖</text>',
            '<text x="0" y="-30" font-size="8" text-anchor="middle" fill="#9D4EDD" font-weight="bold">',
            truncated,
            '</text>',
            '</g>'
        ));
    }

    function _generateFragments(Fragment[] memory fragments, uint256 level) private pure returns (string memory) {
        if (fragments.length == 0) return '';
        
        uint256 displayCount = fragments.length > 15 ? 15 : fragments.length;
        string memory svg = '<g id="fragments">';
        
        for (uint256 i = 0; i < displayCount; i++) {
            uint256 x = 50 + (i % 5) * 60;
            uint256 y = 300 + (i / 5) * 30;
            
            (string memory color, string memory icon) = LibEvolution.getFragmentVisual(fragments[i].fragmentType);
            
            svg = string(abi.encodePacked(
                svg,
                '<g transform="translate(', x.toString(), ',', y.toString(), ')">',
                '<circle r="12" fill="', color, '" opacity="0.95" stroke="#FFFFFF" stroke-width="2" filter="url(#glow)"/>',
                '<text y="5" font-family="Arial" font-size="12" font-weight="bold" text-anchor="middle" fill="#0A0A0A">',
                icon,
                '</text>',
                '</g>'
            ));
        }
        
        if (fragments.length > 15) {
            svg = string(abi.encodePacked(
                svg,
                '<text x="380" y="370" font-family="monospace" font-size="10" text-anchor="end" fill="#39FF14">+',
                (fragments.length - 15).toString(),
                '</text>'
            ));
        }
        
        return string(abi.encodePacked(svg, '</g>'));
    }

    function _truncateString(string memory str, uint256 maxLength) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length <= maxLength) return str;
        
        bytes memory truncated = new bytes(maxLength - 3);
        for (uint256 i = 0; i < maxLength - 3; i++) {
            truncated[i] = strBytes[i];
        }
        
        return string(abi.encodePacked(truncated, "..."));
    }
}
