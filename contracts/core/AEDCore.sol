// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AppStorage.sol";
import "./AEDConstants.sol";
import "../libraries/LibAdmin.sol";

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
}
