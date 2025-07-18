// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";


library LibMinting {
    using LibAppStorage for AppStorage;
    
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool withEnhancements
    ) internal returns (uint256) {
        require(bytes(name).length >= 1 && bytes(name).length <= 64, "Invalid name length");
        require(withEnhancements || LibAppStorage.appStorage().withSubdomains(tld, true, true), "Subdomains not enabled");
        bytes32 normalizedDomain = LibMinting.normalizeDomain(name);
        require(!LibAppStorage.appStorage().domainExists[normalizedDomain], "Domain exists");
        string memory normalizedName = string(abi.encodePacked(name));
        // Register domain using LibMinting (withEnhancements = enableSubdomains for now)
        LibMinting.registerDomain(normalizedName, tld, withEnhancements);

        // Compose full domain for lookup
        string memory fullName = string(abi.encodePacked(normalizedName, ".", tld));

        // Return tokenId (from storage)
        address owner = LibMinting.getDomainOwner(fullName);
        return owner == msg.sender
            ? LibAppStorage.appStorage().domainToTokenId[fullName]
            : 0;
    }

    function getDomainOwner(string calldata domain) external view returns (address) {
        return LibMinting.getDomainOwner(domain);
    }

    // Add other functions as thin wrappers delegating to LibMinting as needed

    /**
     * @notice Batch register multiple domains in a single transaction.
     * @param names Array of domain names.
     * @param tlds Array of TLDs.
     * @param enableSubdomains Array of booleans for subdomain enablement.
     * @return tokenIds Array of minted token IDs.
     * @dev Emits DomainRegistered events for each domain (if implemented in LibMinting).
     */
    function batchRegisterDomains(
        string[] calldata names,
        string[] calldata tlds,
        bool[] calldata enableSubdomains
    ) external payable returns (uint256[] memory tokenIds) {
        require(
            names.length == tlds.length && names.length == enableSubdomains.length,
            "Input array length mismatch"
        );
        tokenIds = new uint256[](names.length);
        uint256 totalValue = 0;
        for (uint256 i = 0; i < names.length; ) {
            // Could use unchecked for increment
            tokenIds[i] = LibMinting.registerDomain(names[i], tlds[i], enableSubdomains[i]);
            // If registerDomain is payable, sum up required value
            // totalValue += ...;
            unchecked { ++i; }
        }
        // If needed, check msg.value == totalValue;
        // if (msg.value != totalValue) revert InsufficientFunds();
        // Send any excess funds back to sender
        // if (totalValue > 0) payable(msg.sender).transfer(totalValue);
        return tokenIds;
    }
}
