// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ValidationLib
 * @dev Library for domain name and label validation
 */
library LibValidation {
    uint256 constant MIN_NAME_LENGTH = 3;
    uint256 constant MAX_NAME_LENGTH = 63;

    error InvalidNameLength();
    error InvalidNameFormat();
    error EmptyLabel();

    function validateDomainName(string memory name) internal pure {
        bytes memory nameBytes = bytes(name);
        uint256 nameLength = nameBytes.length;
        
        if (nameLength < MIN_NAME_LENGTH || nameLength > MAX_NAME_LENGTH) {
            revert InvalidNameLength();
        }
        
        _validateCharacters(nameBytes);
    }

    function validateLabel(string memory label) internal pure {
        bytes memory labelBytes = bytes(label);
        if (labelBytes.length == 0) revert EmptyLabel();
        
        // Check for leading/trailing hyphens
        if (labelBytes[0] == "-" || labelBytes[labelBytes.length - 1] == "-") {
            revert InvalidNameFormat();
        }
        
        _validateCharacters(labelBytes);
    }

    function normalizeName(string memory name) internal pure returns (string memory) {
        bytes memory nameBytes = bytes(name);
        bytes memory lowerBytes = new bytes(nameBytes.length);
        
        for (uint256 i = 0; i < nameBytes.length; i++) {
            bytes1 char = nameBytes[i];
            if (char >= 0x41 && char <= 0x5A) {
                lowerBytes[i] = bytes1(uint8(char) + 32);
            } else {
                lowerBytes[i] = char;
            }
        }
        
        return string(lowerBytes);
    }

    function _validateCharacters(bytes memory nameBytes) private pure {
        for (uint256 i = 0; i < nameBytes.length; i++) {
            bytes1 char = nameBytes[i];
            if (
                !(char >= 0x61 && char <= 0x7A) &&  // a-z
                !(char >= 0x30 && char <= 0x39) &&  // 0-9
                char != 0x2D                        // hyphen
            ) {
                revert InvalidNameFormat();
            }
        }
    }
}