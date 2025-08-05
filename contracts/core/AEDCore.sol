// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AppStorage.sol";
import "./AEDConstants.sol";
import "../libraries/LibAdmin.sol";
import "../libraries/LibReverse.sol";

abstract contract AEDCore is Initializable, AEDConstants {
    using LibAppStorage for AppStorage;
    using LibAdmin for AppStorage;
    
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event DomainTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event SubdomainCreated(string indexed subdomain, string indexed parent, address indexed owner);
    
    function __AEDCore_init() internal onlyInitializing {
        AppStorage storage s = LibAppStorage.appStorage();
        s.nextTokenId = 1;
        s.baseURI = "https://api.alsania.io/metadata/";
    }
    
    function getNextTokenId() external view returns (uint256) {
        return LibAppStorage.appStorage().nextTokenId;
    }
    
    function isRegistered(string calldata name, string calldata tld) external view returns (bool) {
        string memory fullDomain = string(abi.encodePacked(name, ".", tld));
        return LibAppStorage.appStorage().domainExists[fullDomain];
    }
    
    function getDomainInfo(uint256 tokenId) external view returns (Domain memory) {
        require(_tokenExists(tokenId), "Token does not exist");
        return LibAppStorage.appStorage().domains[tokenId];
    }
    
    function getUserDomains(address user) external view returns (string[] memory) {
        return LibAppStorage.appStorage().userDomains[user];
    }
    
    function getTotalRevenue() external view returns (uint256) {
        return LibAppStorage.appStorage().totalRevenue;
    }
    
    function getDomainByTokenId(uint256 tokenId) external view returns (string memory) {
        require(_tokenExists(tokenId), "Token does not exist");
        return LibAppStorage.appStorage().tokenIdToDomain[tokenId];
    }
    
    function getTokenIdByDomain(string calldata domain) external view returns (uint256) {
        uint256 tokenId = LibAppStorage.appStorage().domainToTokenId[domain];
        require(tokenId != 0, "Domain not found");
        return tokenId;
    }
    
    function getDomainFeatures(uint256 tokenId) external view returns (uint256) {
        require(_tokenExists(tokenId), "Token does not exist");
        return LibAppStorage.appStorage().domainFeatures[tokenId];
    }
    
    function isFeatureEnabled(uint256 tokenId, uint256 feature) external view returns (bool) {
        require(_tokenExists(tokenId), "Token does not exist");
        return (LibAppStorage.appStorage().domainFeatures[tokenId] & feature) != 0;
    }
    
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.appStorage().owners[tokenId] != address(0);
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        address owner = s.owners[tokenId];
        return (spender == owner || 
                s.tokenApprovals[tokenId] == spender || 
                s.operatorApprovals[owner][spender]);
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to zero address");
        
        // Clear approvals
        delete s.tokenApprovals[tokenId];
        
        // Update balances
        s.balances[from]--;
        s.balances[to]++;
        s.owners[tokenId] = to;
        
        // Update domain owner
        s.domains[tokenId].owner = to;
        
        // Update user domain arrays
        string memory domain = s.tokenIdToDomain[tokenId];
        _removeFromUserDomains(from, domain);
        s.userDomains[to].push(domain);
        
        // Handle reverse resolution updates
        LibReverse.handleDomainTransfer(from, to, domain);
        
        emit DomainTransferred(tokenId, from, to);
    }
    
    function _approve(address to, uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.tokenApprovals[tokenId] = to;
    }
    
    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "Approve to caller");
        AppStorage storage s = LibAppStorage.appStorage();
        s.operatorApprovals[owner][operator] = approved;
    }
    
    function _removeFromUserDomains(address user, string memory domain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        string[] storage userDomains = s.userDomains[user];
        
        for (uint256 i = 0; i < userDomains.length; i++) {
            if (keccak256(bytes(userDomains[i])) == keccak256(bytes(domain))) {
                // Move last element to current position and pop
                userDomains[i] = userDomains[userDomains.length - 1];
                userDomains.pop();
                break;
            }
        }
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // Hook for additional logic before transfers
        // Can be overridden by modules
    }
    
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // Hook for additional logic after transfers  
        // Can be overridden by modules
    }
}
