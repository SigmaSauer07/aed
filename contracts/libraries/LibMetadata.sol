// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibMetadata {
    using LibAppStorage for AppStorage;
    using Strings for uint256;
    
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
        
        string memory svg = string(abi.encodePacked(
            '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
            '<defs>',
            '<linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />',
            '<stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />',
            '</linearGradient>',
            '</defs>',
            '<rect width="400" height="400" fill="url(#bg)"/>',
            '<circle cx="200" cy="150" r="60" fill="rgba(255,255,255,0.1)"/>',
            '<text x="200" y="200" font-family="Arial, sans-serif" font-size="18" font-weight="bold" ',
            'text-anchor="middle" fill="white">',
            truncatedDomain,
            '</text>',
            '<text x="200" y="250" font-family="Arial, sans-serif" font-size="14" ',
            'text-anchor="middle" fill="rgba(255,255,255,0.8)">',
            domainInfo.isSubdomain ? "Subdomain" : "Domain",
            '</text>',
            '<text x="200" y="320" font-family="Arial, sans-serif" font-size="12" ',
            'text-anchor="middle" fill="rgba(255,255,255,0.6)">',
            'Alsania Enhanced Domains',
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
    function contractURI() internal pure returns (string memory) {
        string memory json = string(abi.encodePacked(
            '{"name":"Alsania Enhanced Domains",',
            '"description":"A comprehensive domain name system with enhanced features",',
            '"image":"https://api.alsania.io/contract-image.png",',
            '"external_link":"https://alsania.io",',
            '"seller_fee_basis_points":250,',
            '"fee_recipient":"0x0000000000000000000000000000000000000000"}'
        ));
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }
}