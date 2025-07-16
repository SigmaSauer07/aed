// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDMinting.sol";
import "../../libraries/LibValidation.sol";
import "../../libraries/LibMinting.sol";

/**
 * @title AEDMinting
 * @dev Stateless module: delegates all business logic to LibMinting
 */
abstract contract AEDMinting is ModuleBase, IAEDMinting {
    using LibValidation for string;

    // using LibMinting for LibMinting.domainData; // Removed: not needed for current usage

    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) external payable returns (uint256) {
        return _registerDomainInternal(name, tld, enableSubdomains);
    }

    function _registerDomainInternal(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) internal returns (uint256) {
        // Validation and normalization
        name.validateDomainName();
        string memory normalizedName = name.normalizeName();
        // Register domain using LibMinting (withEnhancements = enableSubdomains for now)
        LibMinting.registerDomain(normalizedName, tld, enableSubdomains);

        // Compose full domain for lookup
        string memory fullName = string(abi.encodePacked(normalizedName, ".", tld));

        // Return tokenId (from storage)
        address owner = LibMinting.getDomainOwner(fullName);
        return owner == msg.sender
            ? LibAppStorage.getStorage().domainToTokenId[fullName]
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
            tokenIds[i] = _registerDomainInternal(names[i], tlds[i], enableSubdomains[i]);
            // If registerDomain is payable, sum up required value
            // totalValue += ...;
            unchecked { ++i; }
        }
        // If needed, check msg.value == totalValue;
    }
}