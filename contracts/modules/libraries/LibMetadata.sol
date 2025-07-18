// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibAppStorage.sol";
import "../../core/AEDConstants.sol";

library LibMetadata {
    using LibAppStorage for AppStorage;
    
    event ProfileUpdated(uint256 indexed tokenId, string uri);
    event ImageUpdated(uint256 indexed tokenId, string uri);
    
    function setProfileURI(uint256 tokenId, string calldata uri) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] != address(0), "Nonexistent token");
        
        s.profileURIs[tokenId] = uri;
        emit ProfileUpdated(tokenId, uri);
    }
    
    function setImageURI(uint256 tokenId, string calldata uri) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] != address(0), "Nonexistent token");
        
        s.imageURIs[tokenId] = uri;
        emit ImageUpdated(tokenId, uri);
    }
    
    function getProfileURI(uint256 tokenId) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.profileURIs[tokenId];
    }
    
    function getImageURI(uint256 tokenId) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.imageURIs[tokenId];
    }
}