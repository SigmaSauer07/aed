// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "./LibBadges.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibMetadata {
    using LibAppStorage for AppStorage;
    using Strings for uint256;

    // Default background images
    string constant DOMAIN_BG_URI = "ipfs://bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png";
    string constant SUBDOMAIN_BG_URI = "ipfs://bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png";
    
    event ProfileURIUpdated(uint256 indexed tokenId, string uri);
    event ImageURIUpdated(uint256 indexed tokenId, string uri);
    
    function setProfileURI(uint256 tokenId, string calldata uri) internal {
        require(LibAppStorage.tokenExists(tokenId), "Token does not exist");
        AppStorage storage s = LibAppStorage.appStorage();
        
        s.profileURIs[tokenId] = uri;
        s.domains[tokenId].profileURI = uri;
        
        emit ProfileURIUpdated(tokenId, uri);
    }
    
    function setImageURI(uint256 tokenId, string calldata uri) internal {
        require(LibAppStorage.tokenExists(tokenId), "Token does not exist");
        AppStorage storage s = LibAppStorage.appStorage();
        
        s.imageURIs[tokenId] = uri;
        s.domains[tokenId].imageURI = uri;
        
        emit ImageURIUpdated(tokenId, uri);
    }
    
    function getProfileURI(uint256 tokenId) internal view returns (string memory) {
        return LibAppStorage.appStorage().profileURIs[tokenId];
    }
    
    function getImageURI(uint256 tokenId) internal view returns (string memory) {
        return LibAppStorage.appStorage().imageURIs[tokenId];
    }
    
    /**
     * @dev Generates tokenURI with JSON metadata (UPDATED with evolution/badges)
     */
    function tokenURI(uint256 tokenId) internal view returns (string memory) {
        require(LibAppStorage.tokenExists(tokenId), "Token does not exist");
        
        AppStorage storage s = LibAppStorage.appStorage();
        string memory domain = s.tokenIdToDomain[tokenId];
        Domain memory domainInfo = s.domains[tokenId];
        
        // Use custom image if set, otherwise generate evolved SVG
        string memory imageURI = bytes(domainInfo.imageURI).length > 0 
            ? domainInfo.imageURI 
            : _generateEvolvedSVG(tokenId, domain, domainInfo);
        
        // Build JSON metadata with evolution attributes
        string memory json = string(abi.encodePacked(
            '{"name":"', domain, '",',
            '"description":"Alsania Enhanced Domain - ', domain, '",',
            '"image":"', imageURI, '",',
            '"external_url":"https://alsania.io/domain/', domain, '",',
            '"attributes":[',
                _buildAttributes(tokenId, domainInfo),
            ']}'
        ));
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }
    
    /**
     * @dev Generate evolved SVG with badges and evolution frame
     */
    function _generateEvolvedSVG(
        uint256 tokenId,
        string memory domain,
        Domain memory domainInfo
    ) private view returns (string memory) {
        string memory truncatedDomain = _truncateDomain(domain, 20);
        string memory bgURI = domainInfo.isSubdomain ? SUBDOMAIN_BG_URI : DOMAIN_BG_URI;
        
        // Get evolution data
        uint256 evolutionLevel = LibBadges.getEvolutionLevel(tokenId);
        string memory badgesSVG = LibBadges.getBadgeSVG(tokenId);
        string memory frameColor = _getFrameColor(evolutionLevel);
        uint256 frameWidth = 2 + (evolutionLevel / 2); // Thicker frame as you evolve
        
        // Check if AI subdomain
        AppStorage storage s = LibAppStorage.appStorage();
        bool isAI = bytes(s.aiModelType[tokenId]).length > 0;
        string memory aiIndicator = isAI ? _generateAIIndicator(s.aiModelType[tokenId]) : "";
        
        string memory svg = string(abi.encodePacked(
            '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
            '<defs>',
            // Metallic gradient for AI capability badges
            '<linearGradient id="metalGrad" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.3"/>',
            '<stop offset="50%" stop-color="#FFFFFF" stop-opacity="0.1"/>',
            '<stop offset="100%" stop-color="#000000" stop-opacity="0.2"/>',
            '</linearGradient>',
            '</defs>',
            // Background image
            '<image href="', bgURI, '" x="0" y="0" width="400" height="400"/>',
            // Evolution frame (gets thicker/changes color with level)
            '<rect x="20" y="20" width="360" height="360" rx="15" fill="none" stroke="', frameColor, '" stroke-width="', frameWidth.toString(), '"/>',
            // Inner glow for high levels
            evolutionLevel >= 5 ? '<rect x="25" y="25" width="350" height="350" rx="12" fill="none" stroke="', frameColor, '" stroke-width="1" opacity="0.5"/>' : '',
            // Domain text
            '<text x="200" y="250" font-family="\'Orbitron\', sans-serif" font-size="20" font-weight="bold" text-anchor="middle" fill="#39FF14">',
            truncatedDomain,
            '</text>'
        ));
        
        svg = string(abi.encodePacked(
            svg,
            // Type text
            '<text x="200" y="290" font-family="\'Orbitron\', sans-serif" font-size="14" text-anchor="middle" fill="#39FF14">',
            domainInfo.isSubdomain ? (isAI ? "AI Subdomain" : "Subdomain") : "Domain",
            '</text>',
            // Evolution level indicator
            evolutionLevel > 0 ? string(abi.encodePacked(
                '<text x="200" y="315" font-family="monospace" font-size="10" text-anchor="middle" fill="#00F6FF">',
                'Level ', evolutionLevel.toString(),
                '</text>'
            )) : '',
            // AI model indicator
            aiIndicator,
            // Badge layer
            badgesSVG,
            '</svg>'
        ));
        
        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        ));
    }
    
    /**
     * @dev Generate AI model indicator
     */
    function _generateAIIndicator(string memory modelType) private pure returns (string memory) {
        return string(abi.encodePacked(
            '<g transform="translate(350, 50)">',
            '<circle r="20" fill="#9D4EDD" opacity="0.9"/>',
            '<text x="0" y="6" font-size="16" text-anchor="middle" fill="#FFFFFF">🤖</text>',
            '<text x="0" y="-25" font-size="8" text-anchor="middle" fill="#9D4EDD">', _truncateString(modelType, 10), '</text>',
            '</g>'
        ));
    }
    
    /**
     * @dev Get frame color based on evolution level
     */
    function _getFrameColor(uint256 level) private pure returns (string memory) {
        if (level == 0) return "#39FF14";      // Neon green (default)
        if (level < 5) return "#00F6FF";       // Cyan (early evolution)
        if (level < 10) return "#FF2E92";      // Pink (mid evolution)
        if (level < 15) return "#9D4EDD";      // Purple (advanced)
        return "#FFD700";                      // Gold (max evolution)
    }
    
    /**
     * @dev Build attributes JSON including evolution/badges
     */
    function _buildAttributes(uint256 tokenId, Domain memory domainInfo) private view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        uint256 evolutionLevel = LibBadges.getEvolutionLevel(tokenId);
        Badge[] memory badges = LibBadges.getTokenBadges(tokenId);
        bool isAI = bytes(s.aiModelType[tokenId]).length > 0;
        
        string memory attrs = string(abi.encodePacked(
            '{"trait_type":"TLD","value":"', domainInfo.tld, '"},',
            '{"trait_type":"Type","value":"', domainInfo.isSubdomain ? (isAI ? "AI Subdomain" : "Subdomain") : "Domain", '"},',
            '{"trait_type":"Evolution Level","value":', evolutionLevel.toString(), '},',
            '{"trait_type":"Total Badges","value":', badges.length.toString(), '},',
            '{"trait_type":"Subdomains","value":', domainInfo.subdomainCount.toString(), '},',
            '{"trait_type":"Features","value":', _getFeatureCount(tokenId).toString(), '}'
        ));
        
        // Add AI model type if AI subdomain
        if (isAI) {
            attrs = string(abi.encodePacked(
                attrs,
                ',{"trait_type":"AI Model","value":"', s.aiModelType[tokenId], '"}'
            ));
            
            // Count capability badges
            uint256 capabilityCount = 0;
            for (uint256 i = 0; i < badges.length; i++) {
                if (badges[i].isCapability) capabilityCount++;
            }
            
            attrs = string(abi.encodePacked(
                attrs,
                ',{"trait_type":"AI Capabilities","value":', capabilityCount.toString(), '}'
            ));
        }
        
        return attrs;
    }
    
    /**
     * @dev Truncate domain name for display
     */
    function _truncateDomain(string memory domain, uint256 maxLength) private pure returns (string memory) {
        bytes memory domainBytes = bytes(domain);
        if (domainBytes.length <= maxLength) {
            return domain;
        }
        
        bytes memory truncated = new bytes(maxLength - 3);
        for (uint256 i = 0; i < maxLength - 3; i++) {
            truncated[i] = domainBytes[i];
        }
        
        return string(abi.encodePacked(truncated, "..."));
    }
    
    /**
     * @dev Truncate string
     */
    function _truncateString(string memory str, uint256 maxLength) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length <= maxLength) {
            return str;
        }
        
        bytes memory truncated = new bytes(maxLength);
        for (uint256 i = 0; i < maxLength; i++) {
            truncated[i] = strBytes[i];
        }
        
        return string(truncated);
    }
    
    /**
     * @dev Get enabled features count
     */
    function _getFeatureCount(uint256 tokenId) private view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 features = s.domainFeatures[tokenId];
        uint256 count = 0;
        
        while (features > 0) {
            if ((features & 1) == 1) {
                count++;
            }
            features >>= 1;
        }
        
        return count;
    }
    
    /**
     * @dev Contract-level metadata
     */
    function contractURI() internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();

        string memory collectionName = bytes(s.name).length > 0
            ? s.name
            : "Alsania Enhanced Domains";

        string memory description = bytes(s.globalDescription).length > 0
            ? s.globalDescription
            : "Evolving domain names with AI identity support and achievement badges";

        string memory json = string(abi.encodePacked(
            '{"name":"', collectionName, '",',
            '"description":"', description, '",',
            '"image":"https://api.alsania.io/contract-image.png",',
            '"external_link":"https://alsania.io",',
            '"seller_fee_basis_points":250,',
            '"fee_recipient":"', _addressToString(s.feeCollector), '"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function _addressToString(address account) private pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(account)), 20);
    }
}
