// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

library LibMetadata {
    using LibAppStorage for AppStorage;
    
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
}