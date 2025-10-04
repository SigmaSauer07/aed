// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "./LibAppStorage.sol";
import "./LibMinting.sol";

library LibReverse {
    using LibAppStorage for AppStorage;
    
    event ReverseRecordSet(address indexed addr, string indexed domain);
    event ReverseRecordCleared(address indexed addr, string indexed domain);
    
    /**
     * @dev Sets the reverse record for the caller
     * @param domain The domain to set as reverse record
     */
    function setReverseRecord(string calldata domain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        string memory normalizedDomain = LibMinting.normalizeLabel(domain);

        // Verify the caller owns the domain
        uint256 tokenId = s.domainToTokenId[normalizedDomain];
        require(tokenId != 0, "Domain not found");
        require(s.owners[tokenId] == msg.sender, "Not domain owner");

        // Clear previous reverse record if exists
        string memory oldDomain = s.reverseRecords[msg.sender];
        if (bytes(oldDomain).length > 0) {
            delete s.reverseOwners[oldDomain];
        }

        // Set new reverse record
        s.reverseRecords[msg.sender] = normalizedDomain;
        s.reverseOwners[normalizedDomain] = msg.sender;

        emit ReverseRecordSet(msg.sender, normalizedDomain);
    }
    
    /**
     * @dev Clears the reverse record for the caller
     */
    function clearReverseRecord() internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        string memory domain = s.reverseRecords[msg.sender];
        require(bytes(domain).length > 0, "No reverse record set");
        
        // Clear reverse record
        delete s.reverseRecords[msg.sender];
        delete s.reverseOwners[domain];
        
        emit ReverseRecordCleared(msg.sender, domain);
    }
    
    /**
     * @dev Sets reverse record for a specific address (admin only)
     * @param addr The address to set reverse record for
     * @param domain The domain to set as reverse record
     */
    function setReverseRecordFor(address addr, string calldata domain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        string memory normalizedDomain = LibMinting.normalizeLabel(domain);

        // Verify domain exists and is owned by the address
        uint256 tokenId = s.domainToTokenId[normalizedDomain];
        require(tokenId != 0, "Domain not found");
        require(s.owners[tokenId] == addr, "Address does not own domain");

        // Clear previous reverse record if exists
        string memory oldDomain = s.reverseRecords[addr];
        if (bytes(oldDomain).length > 0) {
            delete s.reverseOwners[oldDomain];
        }

        // Set new reverse record
        s.reverseRecords[addr] = normalizedDomain;
        s.reverseOwners[normalizedDomain] = addr;

        emit ReverseRecordSet(addr, normalizedDomain);
    }
    
    /**
     * @dev Gets the primary domain for an address
     * @param addr The address to lookup
     * @return domain The primary domain, empty string if none set
     */
    function getPrimaryDomain(address addr) internal view returns (string memory) {
        return LibAppStorage.appStorage().reverseRecords[addr];
    }
    
    /**
     * @dev Gets the address that has set a domain as primary
     * @param domain The domain to lookup
     * @return addr The address, zero address if none set
     */
    function getDomainPrimaryOwner(string calldata domain) internal view returns (address) {
        string memory normalizedDomain = LibMinting.normalizeLabel(domain);
        return LibAppStorage.appStorage().reverseOwners[normalizedDomain];
    }
    
    /**
     * @dev Checks if an address has a reverse record set
     * @param addr The address to check
     * @return hasRecord True if address has a reverse record
     */
    function hasReverseRecord(address addr) internal view returns (bool) {
        return bytes(LibAppStorage.appStorage().reverseRecords[addr]).length > 0;
    }
    
    /**
     * @dev Checks if a domain is set as someone's primary domain
     * @param domain The domain to check
     * @return isPrimary True if domain is set as primary
     */
    function isDomainPrimary(string calldata domain) internal view returns (bool) {
        string memory normalizedDomain = LibMinting.normalizeLabel(domain);
        return LibAppStorage.appStorage().reverseOwners[normalizedDomain] != address(0);
    }
    
    /**
     * @dev Gets all domains owned by an address
     * @param addr The address to lookup
     * @return domains Array of domain names
     */
    function getOwnedDomains(address addr) internal view returns (string[] memory) {
        return LibAppStorage.appStorage().userDomains[addr];
    }
    
    /**
     * @dev Resolves an address to its primary domain with fallback
     * @param addr The address to resolve
     * @return domain The primary domain or first owned domain
     */
    function resolveAddress(address addr) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Check for primary domain first
        string memory primaryDomain = s.reverseRecords[addr];
        if (bytes(primaryDomain).length > 0) {
            return primaryDomain;
        }
        
        // Fallback to first owned domain
        string[] memory ownedDomains = s.userDomains[addr];
        if (ownedDomains.length > 0) {
            return ownedDomains[0];
        }
        
        return "";
    }
    
    /**
     * @dev Automatically updates reverse record when domain is transferred
     * @param from Previous owner
     * @param to New owner  
     * @param domain The domain being transferred
     */
    function handleDomainTransfer(address from, address to, string memory domain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // If the domain was the primary domain for the previous owner, clear it
        if (keccak256(bytes(s.reverseRecords[from])) == keccak256(bytes(domain))) {
            delete s.reverseRecords[from];
            delete s.reverseOwners[domain];
            emit ReverseRecordCleared(from, domain);
        }
        
        // If new owner doesn't have a primary domain, set this as primary
        if (bytes(s.reverseRecords[to]).length == 0) {
            s.reverseRecords[to] = domain;
            s.reverseOwners[domain] = to;
            emit ReverseRecordSet(to, domain);
        }
    }
    
    /**
     * @dev Batch resolve multiple addresses
     * @param addresses Array of addresses to resolve
     * @return domains Array of resolved domains
     */
    function batchResolveAddresses(address[] calldata addresses) internal view returns (string[] memory) {
        string[] memory domains = new string[](addresses.length);
        
        for (uint256 i = 0; i < addresses.length; i++) {
            domains[i] = resolveAddress(addresses[i]);
        }
        
        return domains;
    }
}