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
            : _generateSVG(domain, domainInfo);
        
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
            if (features & 1 == 1) {
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
