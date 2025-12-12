// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibMetadata {
    using LibAppStorage for AppStorage;
    using Strings for uint256;

    // Default background images for domains and subdomains
    // These IPFS URIs point to pinned PNGs hosted on Pinata.  If you change the pin or host,
    // update these constants accordingly.
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
     * @dev Generates tokenURI with JSON metadata
     * @param tokenId The token ID
     * @return uri The complete tokenURI
     */
    function tokenURI(uint256 tokenId) internal view returns (string memory) {
        require(LibAppStorage.tokenExists(tokenId), "Token does not exist");

        AppStorage storage s = LibAppStorage.appStorage();
        string memory domain = s.tokenIdToDomain[tokenId];
        Domain memory domainInfo = s.domains[tokenId];

        // Use custom image if set, otherwise generate SVG
        string memory imageURI = bytes(domainInfo.imageURI).length > 0
            ? domainInfo.imageURI
            : _generateSVG(domain, domainInfo, tokenId);

        // Build JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name":"', domain, '",',
            '"description":"Alsania Enhanced Domain - ', domain, '",',
            '"image":"', imageURI, '",',
            '"external_url":"https://alsania.io/domain/', domain, '",',
            '"attributes":[',
                '{"trait_type":"TLD","value":"', domainInfo.tld, '"},',
                '{"trait_type":"Subdomains","value":', domainInfo.subdomainCount.toString(), '},',
                '{"trait_type":"Type","value":"', domainInfo.isSubdomain ? "Subdomain" : "Domain", '"},',
                '{"trait_type":"Features","value":', _getFeatureCount(tokenId).toString(), '}',
            ']}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

     /**
     * @dev Generates dynamic SVG for domains with evolution support
     * @param domain The domain name
     * @param domainInfo The domain information
     * @param tokenId The token ID (needed to fetch fragments)
     * @return svg The base64 encoded SVG
     */
    function _generateSVG(string memory domain, Domain memory domainInfo, uint256 tokenId) private view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();

        string memory truncatedDomain = _truncateDomain(domain, 20);
        string memory bgURI = domainInfo.isSubdomain ? SUBDOMAIN_BG_URI : DOMAIN_BG_URI;

        // Get evolution data
        uint256 evolutionLevel = s.evolutionLevels[tokenId];
        Fragment[] memory fragments = s.tokenFragments[tokenId];

        // Generate frame based on evolution level
        string memory frame = _generateEvolutionFrame(evolutionLevel);

        // Generate badge display
        string memory badges = _generateBadges(fragments);

        string memory svg = string(abi.encodePacked(
            '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
            '<defs>',
            '<linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" stop-color="#0A2472"/>',
            '<stop offset="100%" stop-color="#1E3A8A"/>',
            '</linearGradient>',
            '<filter id="glow"><feGaussianBlur stdDeviation="3"/></filter>',
            '</defs>',
            // Background
            '<rect width="400" height="400" fill="url(#bg)"/>',
            // Background image overlay
            '<image href="', bgURI, '" x="0" y="0" width="400" height="400" opacity="0.3"/>',
            // Evolution frame
            frame,
            // Domain name
            '<rect x="50" y="150" width="300" height="100" rx="15" fill="rgba(10,10,10,0.8)" stroke="#39FF14" stroke-width="2"/>',
            '<text x="200" y="200" font-family="Orbitron, sans-serif" font-size="20" font-weight="bold" ',
            'text-anchor="middle" fill="#39FF14">',
            truncatedDomain,
            '</text>',
            '<text x="200" y="230" font-family="Orbitron, sans-serif" font-size="14" ',
            'text-anchor="middle" fill="#00F6FF">',
            domainInfo.isSubdomain ? "Subdomain" : "Domain",
            '</text>',
            // Evolution level indicator
            _generateLevelIndicator(evolutionLevel),
            // Badges
            badges,
            '</svg>'
        ));

        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        ));
    }

    /**
     * @dev Generate evolution frame based on level
     */
    function _generateEvolutionFrame(uint256 level) private pure returns (string memory) {
        if (level == 0) {
            // Basic frame
            return '<rect x="20" y="20" width="360" height="360" rx="20" fill="none" stroke="#39FF14" stroke-width="3"/>';
        } else if (level <= 2) {
            // Enhanced frame with glow
            return string(abi.encodePacked(
                '<rect x="20" y="20" width="360" height="360" rx="25" fill="none" stroke="#39FF14" stroke-width="4" filter="url(#glow)"/>',
                '<rect x="25" y="25" width="350" height="350" rx="20" fill="none" stroke="#00F6FF" stroke-width="2"/>',
                '<path d="M20,20 L80,20 L20,80 Z" fill="#39FF14" opacity="0.3"/>'
            ));
        } else {
            // Advanced frame with animated elements
            return string(abi.encodePacked(
                '<rect x="15" y="15" width="370" height="370" rx="30" fill="none" stroke="#39FF14" stroke-width="6" filter="url(#glow)"/>',
                '<rect x="20" y="20" width="360" height="360" rx="25" fill="none" stroke="#FF2E92" stroke-width="3"/>',
                '<rect x="25" y="25" width="350" height="350" rx="20" fill="none" stroke="#00F6FF" stroke-width="2"/>',
                '<path d="M15,15 L100,15 L15,100 Z" fill="#FF2E92" opacity="0.4"/>',
                '<path d="M385,385 L300,385 L385,300 Z" fill="#FF2E92" opacity="0.4"/>',
                '<circle cx="200" cy="200" r="175" fill="none" stroke="#FFD700" stroke-width="1" stroke-dasharray="10,5" opacity="0.3"/>'
            ));
        }
    }

    /**
     * @dev Generate level indicator
     */
    function _generateLevelIndicator(uint256 level) private pure returns (string memory) {
        return string(abi.encodePacked(
            '<g transform="translate(350, 50)">',
            '<circle r="25" fill="#0A0A0A" stroke="#39FF14" stroke-width="2"/>',
            '<text y="8" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="#39FF14">',
            _toString(level),
            '</text>',
            '<text y="18" font-family="Arial" font-size="8" text-anchor="middle" fill="#00F6FF">LVL</text>',
            '</g>'
        ));
    }

    /**
     * @dev Generate badge display from fragments
     */
    function _generateBadges(Fragment[] memory fragments) private pure returns (string memory) {
        if (fragments.length == 0) {
            return '';
        }

        string memory badges = '<g id="badges">';

        // Display up to 15 badges (3 rows of 5)
        uint256 displayCount = fragments.length > 15 ? 15 : fragments.length;

        for (uint256 i = 0; i < displayCount; i++) {
            uint256 x = 50 + (i % 5) * 60; // 5 badges per row
            uint256 y = 280 + (i / 5) * 25; // 3 rows max

            string memory color = LibEvolution.getFragmentColor(fragments[i].fragmentType);
            string memory icon = LibEvolution.getFragmentIcon(fragments[i].fragmentType);

            badges = string(abi.encodePacked(
                badges,
                '<g transform="translate(', _toString(x), ',', _toString(y), ')">',
                '<circle r="10" fill="', color, '" opacity="0.9" stroke="#000" stroke-width="1"/>',
                '<text y="4" font-family="Arial" font-size="10" font-weight="bold" text-anchor="middle" fill="#000">',
                icon,
                '</text>',
                '</g>'
            ));
        }

        // If more than 15 fragments, show "+X more" indicator
        if (fragments.length > 15) {
            badges = string(abi.encodePacked(
                badges,
                '<text x="200" y="360" font-family="Arial" font-size="10" text-anchor="middle" fill="#FFD700">',
                '+', _toString(fragments.length - 15), ' more',
                '</text>'
            ));
        }

        badges = string(abi.encodePacked(badges, '</g>'));
        return badges;
    }

    /**
     * @dev Truncates domain name for display
     * @param domain The domain name
     * @param maxLength Maximum length
     * @return truncated The truncated domain
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
     * @dev Gets the number of enabled features for a domain
     * @param tokenId The token ID
     * @return count The feature count
     */
    function _getFeatureCount(uint256 tokenId) private view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 features = s.domainFeatures[tokenId];
        uint256 count = 0;

        // Count bits set in features
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
     * @return uri The contract URI
     */
    function contractURI() internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();

        string memory collectionName = bytes(s.name).length > 0
            ? s.name
            : "Alsania Enhanced Domains";

        string memory description = bytes(s.globalDescription).length > 0
            ? s.globalDescription
            : "A comprehensive domain name system with enhanced features";

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
