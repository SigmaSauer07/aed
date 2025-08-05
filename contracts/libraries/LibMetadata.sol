// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

library LibMetadata {
    using LibAppStorage for AppStorage;
    
    event ProfileURIUpdated(uint256 indexed tokenId, string uri);
    event ImageURIUpdated(uint256 indexed tokenId, string uri);
    
    function setProfileURI(uint256 tokenId, string calldata uri) internal {
        require(_exists(tokenId), "Token does not exist");
        AppStorage storage s = LibAppStorage.s();
        s.domains[tokenId].profileURI = uri;
        s.profileURIs[tokenId] = uri;
        emit ProfileURIUpdated(tokenId, uri);
    }
    
    function setImageURI(uint256 tokenId, string calldata uri) internal {
        require(_exists(tokenId), "Token does not exist");
        AppStorage storage s = LibAppStorage.s();
        s.domains[tokenId].imageURI = uri;
        s.imageURIs[tokenId] = uri;
        emit ImageURIUpdated(tokenId, uri);
    }
    
    function getProfileURI(uint256 tokenId) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.s();
        return s.domains[tokenId].profileURI;
    }
    
    function getImageURI(uint256 tokenId) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.s();
        return s.domains[tokenId].imageURI;
    }
    
    function tokenURI(uint256 tokenId) internal view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        AppStorage storage s = LibAppStorage.s();
        
        string memory domain = s.tokenIdToDomain[tokenId];
        string memory baseURI = s.baseURI;
        
        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, domain))
            : _generateSVG(tokenId, domain);
    }
    
    function _generateSVG(uint256 tokenId, string memory domain) internal pure returns (string memory) {
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">',
            '<defs>',
            '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" style="stop-color:#001f3f;stop-opacity:1" />',
            '<stop offset="100%" style="stop-color:#003366;stop-opacity:1" />',
            '</linearGradient>',
            '</defs>',
            '<rect width="400" height="400" fill="url(#grad1)"/>',
            '<circle cx="200" cy="150" r="80" fill="none" stroke="#39FF14" stroke-width="2" opacity="0.3"/>',
            '<text x="200" y="160" text-anchor="middle" fill="#39FF14" font-size="18" font-family="monospace" font-weight="bold">',
            domain,
            '</text>',
            '<text x="200" y="280" text-anchor="middle" fill="#39FF14" font-size="14" font-family="monospace">',
            'Alsania Enhanced Domain',
            '</text>',
            '<text x="200" y="300" text-anchor="middle" fill="#39FF14" font-size="12" font-family="monospace">',
            'Token ID: ',
            _uint2str(tokenId),
            '</text>',
            '</svg>'
        ));
        
        string memory json = string(abi.encodePacked(
            '{"name":"', domain, '",',
            '"description":"Alsania Enhanced Domain NFT - A sovereign identity in the Web3 ecosystem",',
            '"image":"data:image/svg+xml;base64,', _base64Encode(bytes(svg)), '",',
            '"attributes":[',
            '{"trait_type":"Domain","value":"', domain, '"},',
            '{"trait_type":"Token ID","value":"', _uint2str(tokenId), '"},',
            '{"trait_type":"Type","value":"Enhanced Domain"}',
            ']}'
        ));
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            _base64Encode(bytes(json))
        ));
    }
    
    function _base64Encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        string memory result = new string(4 * ((data.length + 2) / 3));
        
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            
            for { let i := 0 } lt(i, mload(data)) { i := add(i, 3) } {
                let input := shl(248, mload(add(add(data, 32), i)))
                
                mstore8(resultPtr, mload(add(tablePtr, and(shr(250, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(244, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(238, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(232, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
    
    function _uint2str(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.s().owners[tokenId] != address(0);
    }
}
