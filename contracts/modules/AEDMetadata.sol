// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../core/CoreState.sol";
import "../core/AEDConstants.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title AEDMetadata
 * @dev Module for managing on-chain metadata (profile URI, image URI) and generating token URI JSON.
 */
abstract contract AEDMetadata is Initializable, CoreState, AEDConstants {
    using Strings for uint256;
    using Base64 for bytes;

    // Events
    event ProfileUpdated(uint256 indexed tokenId, string newURI);
    event ImageUpdated(uint256 indexed tokenId, string newURI);
    event RoyaltyInfoCalculated(uint256 indexed tokenId, uint256 salePrice, address receiver, uint256 royaltyAmount);

    // Custom errors
    error NonexistentToken();
    error NotAuthorized();
    error InvalidURI();
    error InvalidURIFormat();
    error URIIdentical();
    error DuplicateURIField();
    error URITooLong();
    error EmptyURI();
    error UnsafeURI();

    /// @notice Restricts access to only the token owner or an account with ADMIN_ROLE.
    modifier onlyOwnerOrAdmin(uint256 tokenId) {
        require(
            msg.sender == ownerOf(tokenId) || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized"
        );
        _;
    }

    function __AEDMetadata_init() internal onlyInitializing {
        // No state initialization needed for metadata
    }

    function setProfileURI(uint256 tokenId, string memory uri) external onlyOwnerOrAdmin(tokenId) {
        if (!_exists(tokenId)) revert NonexistentToken();
        bytes memory uriBytes = bytes(uri);
        _validateURI(uriBytes, uri);
        Domain memory domain = domains[tokenId];
        if (_stringEquals(domain.profileURI, uri)) revert URIIdentical();
        if (_stringEquals(domain.imageURI, uri)) revert DuplicateURIField();
        domains[tokenId].profileURI = uri;
        emit ProfileUpdated(tokenId, uri);
    }

    function setImageURI(uint256 tokenId, string memory uri) external onlyOwnerOrAdmin(tokenId) {
        if (!_exists(tokenId)) revert NonexistentToken();
        bytes memory uriBytes = bytes(uri);
        _validateURI(uriBytes, uri);
        Domain memory domain = domains[tokenId];
        if (_stringEquals(domain.imageURI, uri)) revert URIIdentical();
        if (_stringEquals(domain.profileURI, uri)) revert DuplicateURIField();
        domains[tokenId].imageURI = uri;
        emit ImageUpdated(tokenId, uri);
    }

    // Internal URI validation helper
    function _validateURI(bytes memory b, string memory uri) internal pure {
        uint256 uriLength = b.length;
        if (uriLength == 0) revert EmptyURI();
        if (uriLength > MAX_URI_LENGTH) revert URITooLong();
        if (_hasLeadingOrTrailingWhitespaceFromBytes(b)) revert InvalidURIFormat();
        if (!_isValidURI(uri, b)) revert InvalidURIFormat();
        if (!_isSafeURIFromBytes(b)) revert UnsafeURI();
    }

    function _isValidURI(string memory /*uri*/, bytes memory b) private pure returns (bool) {
        // Only allow URIs beginning with http:// or https://
        return _hasHttpOrHttpsPrefix(b);
    }

    function _hasHttpOrHttpsPrefix(bytes memory b) private pure returns (bool) {
        if (b.length >= 7) {
            // "http://"
            if (
                b[0] == 0x68 && b[1] == 0x74 && b[2] == 0x74 && 
                b[3] == 0x70 && b[4] == 0x3a && b[5] == 0x2f && b[6] == 0x2f
            ) {
                return true;
            }
        }
        if (b.length >= 8) {
            // "https://"
            if (
                b[0] == 0x68 && b[1] == 0x74 && b[2] == 0x74 && b[3] == 0x70 &&
                b[4] == 0x73 && b[5] == 0x3a && b[6] == 0x2f && b[7] == 0x2f
            ) {
                return true;
            }
        }
        return false;
    }

    function _isSafeURIFromBytes(bytes memory b) private pure returns (bool) {
        for (uint256 i = 0; i < b.length; ) {
            // Disallow control characters and quotes/newlines
            if (
                b[i] < 0x20 || b[i] == 0x22 || b[i] == 0x7F || 
                b[i] == 0x0A || b[i] == 0x0D
            ) {
                return false;
            }
            unchecked { ++i; }
        }
        return true;
    }

    function _stringEquals(string memory a, string memory b) private pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function _hasLeadingOrTrailingWhitespaceFromBytes(bytes memory b) internal pure returns (bool) {
        if (b.length == 0) return false;
        return (b[0] == 0x20 || b[b.length - 1] == 0x20);
    }

    // Token URI logic (on-chain metadata generation)
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();
        Domain memory domain = domains[tokenId];
        string memory fullName = string(abi.encodePacked(domain.name, ".", domain.tld));
        string memory json = _formatTokenJson(fullName, _getImageURIWithName(domain, fullName), _getAttributes(domain));
        return string(abi.encodePacked("data:application/json;base64,", bytes(json).encode()));
    }

    function _formatTokenJson(string memory name, string memory image, string memory attributes) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{"name":"', _escapeJson(name),
            '","description":"Alsania Enhanced Domain",',
            '"image":"', _escapeJson(image),
            '","attributes":', attributes, '}'
        ));
    }

    function _escapeJson(string memory value) internal pure returns (string memory) {
        bytes memory input = bytes(value);
        bytes memory output = new bytes(input.length * 2); // worst case each char needs escaping
        uint256 j = 0;
        for (uint256 i = 0; i < input.length; i++) {
            bytes1 char = input[i];
            if (char == '"') {
                output[j++] = '\\'; output[j++] = '"';
            } else if (char == '\\') {
                output[j++] = '\\'; output[j++] = '\\';
            } else if (char == 0x08) { // \b
                output[j++] = '\\'; output[j++] = 'b';
            } else if (char == 0x0C) { // \f
                output[j++] = '\\'; output[j++] = 'f';
            } else if (char == 0x0A) { // \n
                output[j++] = '\\'; output[j++] = 'n';
            } else if (char == 0x0D) { // \r
                output[j++] = '\\'; output[j++] = 'r';
            } else if (char == 0x09) { // \t
                output[j++] = '\\'; output[j++] = 't';
            } else {
                output[j++] = char;
            }
        }
        bytes memory trimmed = new bytes(j);
        for (uint256 k = 0; k < j; k++) {
            trimmed[k] = output[k];
        }
        return string(trimmed);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external view returns (address receiver, uint256 royaltyAmount) 
    {
        if (!_exists(tokenId)) revert NonexistentToken();
        receiver = feeCollector;
        royaltyAmount = (salePrice * royaltyBps) / 10000;
        return (receiver, royaltyAmount);
    }

    // Internal image/attribute generation
    function _getImageURIWithName(Domain memory domain, string memory fullName) internal pure returns (string memory) {
        if (bytes(domain.imageURI).length > 0) {
            return domain.imageURI;
        }
        return _generateSVG(domain, fullName);
    }

    function _generateSVG(Domain memory domain, string memory fullName) internal pure returns (string memory) {
        string memory bgImage = domain.isSubdomain ? SUB_BG : DOMAIN_BG;
        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            bytes(_formatSVG(fullName, bgImage)).encode()
        ));
    }

    function _formatSVG(string memory fullName, string memory bgImage) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400">',
            '<defs><style>@import url(\'https://fonts.googleapis.com/css2?family=Permanent+Marker\');</style>',
            '<filter id="glow" x="-50%" y="-50%" width="200%" height="200%">',
            '<feGaussianBlur stdDeviation="2.5" result="blur"/>',
            '<feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>',
            '</filter></defs>',
            '<image href="', bgImage, '" width="400" height="400"/>',
            '<text x="50%" y="92%" text-anchor="middle" dominant-baseline="middle" ',
            'font-family="Permanent Marker" font-size="24" fill="', NEON_GREEN, '" filter="url(#glow)">',
            _escapeJson(fullName),
            '</text></svg>'
        ));
    }

    function _getAttributes(Domain memory domain) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '[{"trait_type":"TLD","value":"', domain.tld,
            '"},{"trait_type":"Type","value":"', domain.isSubdomain ? "Subdomain" : "Domain",
            '"},{"trait_type":"Subdomains","value":"', domain.subdomainCount.toString(), '"}]'
        ));
    }

    // Note: supportsInterface for ERC2981 is handled in main contract override.

    function initializeModule_Metadata() public virtual onlyInitializing {
        // Initialization logic for Metadata module (optional)
    }

}
