// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AEDConstants.sol";

library LibValidation {
    
    // Constants from AEDConstants (hardcoded since it's a contract)
    uint256 constant MIN_NAME_LENGTH = 1;
    uint256 constant MAX_NAME_LENGTH = 63;
    
    /**
     * @dev Validates domain name format and characters
     * @param name The domain name to validate
     * @return isValid True if the name is valid
     */
    function isValidDomainName(string memory name) internal pure returns (bool) {
        bytes memory nameBytes = bytes(name);
        uint256 length = nameBytes.length;
        
        // Check length constraints
        if (length < MIN_NAME_LENGTH || length > MAX_NAME_LENGTH) {
            return false;
        }
        
        // Check for valid characters and format
        for (uint256 i = 0; i < length; i++) {
            bytes1 char = nameBytes[i];
            
            // Allow alphanumeric and hyphens
            if (!_isAlphaNumeric(char) && char != 0x2D) { // 0x2D is hyphen
                return false;
            }
            
            // Cannot start or end with hyphen
            if (char == 0x2D && (i == 0 || i == length - 1)) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Validates TLD format
     * @param tld The TLD to validate
     * @return isValid True if the TLD is valid
     */
    function isValidTLD(string memory tld) internal pure returns (bool) {
        bytes memory tldBytes = bytes(tld);
        uint256 length = tldBytes.length;
        
        // TLD should be 2-10 characters
        if (length < 2 || length > 10) {
            return false;
        }
        
        // Check for valid characters (only letters)
        for (uint256 i = 0; i < length; i++) {
            bytes1 char = tldBytes[i];
            if (!_isLetter(char)) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Normalizes domain name to lowercase
     * @param name The domain name to normalize
     * @return normalized The normalized domain name
     */
    function normalizeDomainName(string memory name) internal pure returns (string memory) {
        bytes memory nameBytes = bytes(name);
        bytes memory normalized = new bytes(nameBytes.length);

        for (uint256 i = 0; i < nameBytes.length; i++) {
            bytes1 char = nameBytes[i];
            // Convert uppercase to lowercase
            if (char >= 0x41 && char <= 0x5A) {
                normalized[i] = bytes1(uint8(char) + 32);
            } else {
                normalized[i] = char;
            }
        }

        return string(normalized);
    }

    /**
     * @dev Converts an arbitrary string to lowercase.
     * @param input The string to normalise
     * @return lower The lowercase string
     */
    function toLower(string memory input) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory lower = new bytes(inputBytes.length);

        for (uint256 i = 0; i < inputBytes.length; i++) {
            bytes1 char = inputBytes[i];
            if (char >= 0x41 && char <= 0x5A) {
                lower[i] = bytes1(uint8(char) + 32);
            } else {
                lower[i] = char;
            }
        }

        return string(lower);
    }
    
    /**
     * @dev Checks if a character is alphanumeric
     * @param char The character to check
     * @return isAlphaNum True if the character is alphanumeric
     */
    function _isAlphaNumeric(bytes1 char) private pure returns (bool) {
        return _isLetter(char) || _isDigit(char);
    }
    
    /**
     * @dev Checks if a character is a letter
     * @param char The character to check
     * @return isLetter True if the character is a letter
     */
    function _isLetter(bytes1 char) private pure returns (bool) {
        return (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A);
    }
    
    /**
     * @dev Checks if a character is a digit
     * @param char The character to check
     * @return isDigit True if the character is a digit
     */
    function _isDigit(bytes1 char) private pure returns (bool) {
        return char >= 0x30 && char <= 0x39;
    }
    
    /**
     * @dev Validates an Ethereum address
     * @param addr The address to validate
     * @return isValid True if the address is valid
     */
    function isValidAddress(address addr) internal pure returns (bool) {
        return addr != address(0);
    }
    
    /**
     * @dev Validates payment amount against required fee
     * @param paid The amount paid
     * @param required The required amount
     * @return isValid True if payment is sufficient
     */
    function isValidPayment(uint256 paid, uint256 required) internal pure returns (bool) {
        return paid >= required;
    }
}