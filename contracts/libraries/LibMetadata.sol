// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../external/oz/utils/Base64.sol";
import "../external/oz/utils/Strings.sol";

library LibMetadata {
    using LibAppStorage for AppStorage;
    using Strings for uint256;

    // Default background images for domains and subdomains
    // These IPFS URIs point to pinned PNGs hosted on Pinata.  If you change the pin or host,
    // update these constants accordingly.
    string constant DOMAIN_BG_URI = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNDAwJyBoZWlnaHQ9JzQwMCcgeG1sbnM9J2h0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnJz48cmVjdCB3aWR0aD0nNDAwJyBoZWlnaHQ9JzQwMCcgZmlsbD0nIzBhMjQ3MicvPjxyZWN0IHg9JzIwJyB5PScyMCcgd2lkdGg9JzM2MCcgaGVpZ2h0PSczNjAnIGZpbGw9JyMwMDAwMDAnIHJ4PScyNCcvPjxjaXJjbGUgY3g9JzIwMCcgY3k9JzIwMCcgcj0nMTQwJyBzdHJva2U9JyMzOWZmMTQnIGZpbGw9J25vbmUnIHN0cm9rZS13aWR0aD0nNCcvPjwvc3ZnPiI7
    string constant SUBDOMAIN_BG_URI = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNDAwJyBoZWlnaHQ9JzQwMCcgeG1sbnM9J2h0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnJz48cmVjdCB3aWR0aD0nNDAwJyBoZWlnaHQ9JzQwMCcgZmlsbD0nIzBhMjQ3MicvPjxyZWN0IHg9JzQwJyB5PSc0MCcgd2lkdGg9JzMyMCcgaGVpZ2h0PSczMjAnIGZpbGw9JyMwMDAwMDAnIHJ4PScyNCcvPjxjaXJjbGUgY3g9JzIwMCcgY3k9JzIwMCcgcj0nMTAwJyBzdHJva2U9JyMzOWZmMTQnIGZpbGw9J25vbmUnIHN0cm9rZS13aWR0aD0nNCcvPjwvc3ZnPiI7
    
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
        string memory stored = LibAppStorage.appStorage().profileURIs[tokenId];
        if (bytes(stored).length == 0) {
            string memory domain = LibAppStorage.appStorage().tokenIdToDomain[tokenId];
            return defaultProfileURI(domain, LibAppStorage.appStorage().domains[tokenId].isSubdomain);
        }
        return stored;
    }

    function getImageURI(uint256 tokenId) internal view returns (string memory) {
        string memory stored = LibAppStorage.appStorage().imageURIs[tokenId];
        if (bytes(stored).length == 0) {
            string memory domain = LibAppStorage.appStorage().tokenIdToDomain[tokenId];
            return defaultImageURI(domain, LibAppStorage.appStorage().domains[tokenId].isSubdomain);
        }
        return stored;
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
            : _generateSVG(domain, domainInfo);
        
        // Build JSON metadata
        string memory description = bytes(s.globalDescription).length > 0
            ? s.globalDescription
            : string(abi.encodePacked("Alsania Enhanced Domain registered for ", domain));

        string memory json = string(abi.encodePacked(
            '{"name":"', domain, '",',
            '"description":"', description, '",',
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
     * @dev Generates dynamic SVG for domains
     * @param domain The domain name
     * @param domainInfo The domain information
     * @return svg The base64 encoded SVG
     */
    function _generateSVG(string memory domain, Domain memory domainInfo) private pure returns (string memory) {
        string memory truncatedDomain = _truncateDomain(domain, 20);
        // Choose the appropriate background URI based on whether this is a subdomain
        string memory bgURI = domainInfo.isSubdomain ? SUBDOMAIN_BG_URI : DOMAIN_BG_URI;
        
        string memory svg = string(abi.encodePacked(
            '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
            // embed background image
            '<image href="', bgURI, '" x="0" y="0" width="400" height="400"/>',
            // overlay domain/subdomain text in neon green
            '<text x="200" y="250" font-family="\'Orbitron\', sans-serif" font-size="20" font-weight="bold" ',
            'text-anchor="middle" fill="#39FF14">',
            truncatedDomain,
            '</text>',
            // overlay type (Domain or Subdomain) below
            '<text x="200" y="290" font-family="\'Orbitron\', sans-serif" font-size="14" ',
            'text-anchor="middle" fill="#39FF14">',
            domainInfo.isSubdomain ? "Subdomain" : "Domain",
            '</text>',
            '</svg>'
        ));
        
        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        ));
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
        string memory json = string(abi.encodePacked(
            '{"name":"Alsania Enhanced Domains",',
            '"description":"Alsania\'s sovereign naming system with programmable enhancements",',
            '"image":"', DOMAIN_BG_URI, '",',
            '"external_link":"https://alsania.io",',
            '"seller_fee_basis_points":250,',
            '"fee_recipient":"', Strings.toHexString(uint160(s.feeCollector), 20), '"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function defaultProfileURI(string memory domain, bool isSubdomain) internal pure returns (string memory) {
        string memory json = string(abi.encodePacked(
            '{"domain":"', domain, '",',
            '"type":"', isSubdomain ? "subdomain" : "domain", '",',
            '"description":"Alsania sovereign identity profile"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function defaultImageURI(string memory domain, bool isSubdomain) internal pure returns (string memory) {
        string memory svg = string(abi.encodePacked(
            '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="400" height="400" fill="#0a2472"/>',
            '<text x="200" y="200" font-family="Orbitron" font-size="22" text-anchor="middle" fill="#39ff14">',
            domain,
            '</text>',
            '<text x="200" y="240" font-family="Rajdhani" font-size="16" text-anchor="middle" fill="#39ff14">',
            isSubdomain ? "Subdomain" : "Domain",
            '</text>',
            '</svg>'
        ));

        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        ));
    }
}