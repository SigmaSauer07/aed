// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibDomainEnhancements {
    /**
     * @dev Extracts the child, parent, and TLD from a domain of the format child.parent.tld.
     * @param domain The domain string to parse.
     * @return child The child part of the domain.
     * @return parent The parent part of the domain.
     * @return tld The top-level domain part of the domain.
     */
    function parseDomain(string memory domain) internal pure returns (string memory child, string memory parent, string memory tld) {
        bytes memory domainBytes = bytes(domain);
        uint256 lastDotIndex = 0;
        uint256 secondLastDotIndex = 0;

        // Iterate over the domain to find the positions of the dots
        for (uint256 i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == '.') {
                secondLastDotIndex = lastDotIndex;
                lastDotIndex = i;
            }
        }

        // Validate the domain structure
        require(lastDotIndex > 0 && secondLastDotIndex > 0, "Invalid domain format");

        // Extract TLD, Parent, and Child
        tld = substring(domain, lastDotIndex + 1, domainBytes.length);
        parent = substring(domain, secondLastDotIndex + 1, lastDotIndex);
        child = substring(domain, 0, secondLastDotIndex);

        // Note: This function does not handle all edge cases, such as:
        // - Domains without a child or parent (e.g., .tld)
        // - Subdomains with additional dots (e.g., sub.child.parent.tld)
        // Consider implementing additional checks and parsing strategies.
    }

    /**
     * @dev Helper function to extract a substring from a string.
     * @param str The original string.
     * @param start The starting index for the substring.
     * @param end The ending index for the substring.
     * @return The extracted substring.
     */
    function substring(string memory str, uint256 start, uint256 end) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(start < end && end <= strBytes.length, "Invalid substring indices");
        bytes memory result = new bytes(end - start);
        
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        
        return string(result);
    }
}