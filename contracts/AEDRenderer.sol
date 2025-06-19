// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IAEDRenderer.sol";

contract AEDRenderer is IAEDRenderer {
    using Strings for uint256;
    
    struct DomainMetadata {
        string name;
        bool isSubdomain;
        bool darkMode;
        string svgImage;
    }
    
    mapping(uint256 => DomainMetadata) private metadata;
    
    function initializeMetadata(
        uint256 tokenId, 
        string memory name, 
        bool darkMode
    ) external {
        metadata[tokenId] = DomainMetadata({
            name: name,
            isSubdomain: false,
            darkMode: darkMode,
            svgImage: ""
        });
    }
    
    function generateSVG(uint256 tokenId) public view returns (string memory) {
        DomainMetadata storage meta = metadata[tokenId];
        string memory bgColor = meta.darkMode ? AEDRegistry.BACKGROUND_DARK : AEDRegistry.BACKGROUND_LIGHT;
        string memory textColor = AEDRegistry.NEON_GREEN;
        string memory borderColor = AEDRegistry.MIDNIGHT_BLUE;
        
        if(meta.isSubdomain) {
            // Tag-shaped subdomain
            return string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="150" viewBox="0 0 300 150">',
                '<rect width="100%" height="100%" fill="', bgColor, '"/>',
                '<path d="M50,25 L250,25 L275,75 L250,125 L50,125 L25,75 Z" fill="', borderColor, '" stroke="', textColor, '" stroke-width="3"/>',
                '<text x="150" y="80" dominant-baseline="middle" text-anchor="middle" fill="', textColor, '" font-family="sans-serif" font-size="20">',
                meta.name,
                '</text>',
                '</svg>'
            ));
        } else {
            // Square domain
            return string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" viewBox="0 0 500 500">',
                '<rect width="100%" height="100%" fill="', bgColor, '"/>',
                '<rect x="100" y="100" width="300" height="300" fill="', borderColor, '" stroke="', textColor, '" stroke-width="5"/>',
                '<text x="250" y="250" dominant-baseline="middle" text-anchor="middle" fill="', textColor, '" font-family="monospace" font-size="32">',
                meta.name,
                '</text>',
                '</svg>'
            ));
        }
    }
    
    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        DomainMetadata storage meta = metadata[tokenId];
        string memory svg = generateSVG(tokenId);
        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        );
        
        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(abi.encodePacked(
                '{"name":"', meta.name, '",',
                '"description":"Alsania Enhanced Domain",',
                '"image":"', image, '",',
                '"attributes":[{"trait_type":"Type","value":"', 
                meta.isSubdomain ? "Subdomain" : "Domain", 
                '"}]}'
            ))
        ));
    }
}