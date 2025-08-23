// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./core/AppStorage.sol";
import "./libraries/LibAdmin.sol";

/// @title AED Core Implementation
/// This contract is designed to be small enough to deploy while maintaining core functionality
contract AEDCoreImplementation is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IERC721
{
    // Direct storage access
    AppStorage private s;

    // Core events
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event DomainTransferred(uint256 indexed tokenId, address indexed from, address indexed to);

    function initialize(
        string memory name,
        string memory symbol,
        address paymentWallet,
        address admin
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(LibAdmin.ADMIN_ROLE, admin);

        s.name = name;
        s.symbol = symbol;
        s.nextTokenId = 1;
        s.baseURI = "https://api.alsania.io/metadata/";
        s.feeCollector = paymentWallet;
        s.admins[admin] = true;

        // Initialize default pricing
        s.enhancementPrices["subdomain"] = 2 ether;
        s.tldPrices["alsania"] = 1 ether;
        s.tldPrices["fx"] = 1 ether;
        s.tldPrices["echo"] = 1 ether;

        // Initialize free TLDs
        s.freeTlds["aed"] = true;
        s.freeTlds["alsa"] = true;
        s.freeTlds["07"] = true;

        // Initialize valid Alsania TLDs (both free and paid)
        s.validTlds["aed"] = true;
        s.validTlds["alsa"] = true;
        s.validTlds["07"] = true;
        s.validTlds["alsania"] = true;
        s.validTlds["fx"] = true;
        s.validTlds["echo"] = true;
    }

    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(DEFAULT_ADMIN_ROLE)
        override
    {}

    // ERC721 interface implementation
    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        address owner = s.owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    function balanceOf(address owner)
        public
        view
        override
        returns (uint256)
    {
        require(owner != address(0), "Zero address query");
        return s.balances[owner];
    }

    function name() public view returns (string memory) {
        return s.name;
    }

    function symbol() public view returns (string memory) {
        return s.symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(s.owners[tokenId] != address(0), "Token does not exist");

        string memory domain = s.tokenIdToDomain[tokenId];
        Domain memory domainInfo = s.domains[tokenId];

        // Use custom image if set, otherwise generate SVG
        string memory imageURI = bytes(domainInfo.imageURI).length > 0
            ? domainInfo.imageURI
            : _generateSVG(domain, domainInfo);

        // Build JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name":"', domain, '",',
            '"description":"Alsania Enhanced Domain - ', domain, '",',
            '"image":"', imageURI, '",',
            '"external_url":"https://alsania.io/domain/', domain, '",',
            '"attributes":[',
                '{"trait_type":"TLD","value":"', domainInfo.tld, '"},',
                '{"trait_type":"Subdomains","value":', _uintToString(domainInfo.subdomainCount), '},',
                '{"trait_type":"Type","value":"', domainInfo.isSubdomain ? "Subdomain" : "Domain", '"},',
                '{"trait_type":"Features","value":', _uintToString(_getFeatureCount(tokenId)), '}',
            ']}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approve to owner");
        require(msg.sender == owner || s.operatorApprovals[owner][msg.sender], "Not approved");

        s.tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(s.owners[tokenId] != address(0), "Token does not exist");
        return s.tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Approve to self");
        s.operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return s.operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        require(from == ownerOf(tokenId), "Wrong owner");
        require(to != address(0), "Invalid recipient");

        // Update balances
        s.balances[from]--;
        s.balances[to]++;

        // Update ownership
        s.owners[tokenId] = to;

        // Clear approval
        s.tokenApprovals[tokenId] = address(0);

        emit Transfer(from, to, tokenId);
        emit DomainTransferred(tokenId, from, to);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        require(from == ownerOf(tokenId), "Wrong owner");
        require(to != address(0), "Invalid recipient");

        // Update balances
        s.balances[from]--;
        s.balances[to]++;

        // Update ownership
        s.owners[tokenId] = to;

        // Clear approval
        s.tokenApprovals[tokenId] = address(0);

        emit Transfer(from, to, tokenId);
        emit DomainTransferred(tokenId, from, to);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = s.owners[tokenId];
        return (spender == owner ||
                s.operatorApprovals[owner][spender] ||
                s.tokenApprovals[tokenId] == spender);
    }

    // Core AED functions
    function getNextTokenId() external view returns (uint256) {
        return s.nextTokenId;
    }

    function isRegistered(string calldata domain) external view returns (bool) {
        return s.domainExists[domain];
    }

    function getDomainInfo(uint256 tokenId) external view returns (Domain memory) {
        require(s.owners[tokenId] != address(0), "Token does not exist");
        return s.domains[tokenId];
    }

    function getUserDomains(address user) external view returns (string[] memory) {
        return s.userDomains[user];
    }

    function getTotalRevenue() external view returns (uint256) {
        return s.totalRevenue;
    }

    // Domain registration function
    function registerDomain(string calldata domain, address owner) external payable {
        // Parse domain into name and TLD
        (string memory name, string memory tld) = _parseDomain(domain);

        // Check if domain is already registered
        require(!s.domainExists[domain], "Domain already registered");

        // Validate TLD
        require(s.validTlds[tld], "Invalid TLD");

        // Check pricing
        uint256 price = s.freeTlds[tld] ? 0 : s.tldPrices[tld];
        require(msg.value >= price, "Insufficient payment");

        // Register the domain
        uint256 tokenId = s.nextTokenId;
        s.nextTokenId++;

        s.domainExists[domain] = true;

        // Store domain info
        s.domains[tokenId] = Domain({
            name: name,
            tld: tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: uint64(block.timestamp + 365 days),
            feeEnabled: false,
            isSubdomain: false,
            owner: owner
        });

        // Store domain mapping for tokenURI
        s.tokenIdToDomain[tokenId] = domain;

        // Set the owner in the owners mapping (required for tokenExists)
        s.owners[tokenId] = owner;

        // Update balances
        s.balances[owner]++;

        // Add to user's domain list
        s.userDomains[owner].push(domain);

        // Collect fees
        if (msg.value > 0) {
            s.totalRevenue += msg.value;
            (bool success, ) = s.feeCollector.call{value: msg.value}("");
            require(success, "Fee transfer failed");
        }

        emit Transfer(address(0), owner, tokenId);
        emit DomainRegistered(domain, owner, tokenId);
    }

    // Helper function to parse domain
    function _parseDomain(string calldata domain) internal pure returns (string memory name, string memory tld) {
        bytes memory domainBytes = bytes(domain);
        uint256 dotIndex = 0;

        // Find the last dot
        for (uint256 i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == ".") {
                dotIndex = i;
            }
        }

        require(dotIndex > 0, "Invalid domain format");

        // Extract name and TLD
        bytes memory nameBytes = new bytes(dotIndex);
        bytes memory tldBytes = new bytes(domainBytes.length - dotIndex - 1);

        for (uint256 i = 0; i < dotIndex; i++) {
            nameBytes[i] = domainBytes[i];
        }

        for (uint256 i = 0; i < tldBytes.length; i++) {
            tldBytes[i] = domainBytes[dotIndex + 1 + i];
        }

        return (string(nameBytes), string(tldBytes));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Generates dynamic SVG for domains
     * @param domain The domain name
     * @param domainInfo The domain information
     * @return svg The base64 encoded SVG
     */
    function _generateSVG(string memory domain, Domain memory domainInfo) private pure returns (string memory) {
        string memory truncatedDomain = _truncateDomain(domain, 20);

        string memory svg = string(abi.encodePacked(
            '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
            '<defs>',
            '<linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />',
            '<stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />',
            '</linearGradient>',
            '</defs>',
            '<rect width="400" height="400" fill="url(#bg)"/>',
            '<circle cx="200" cy="150" r="60" fill="rgba(255,255,255,0.1)"/>',
            '<text x="200" y="200" font-family="Arial, sans-serif" font-size="18" font-weight="bold" ',
            'text-anchor="middle" fill="white">',
            truncatedDomain,
            '</text>',
            '<text x="200" y="250" font-family="Arial, sans-serif" font-size="14" ',
            'text-anchor="middle" fill="rgba(255,255,255,0.8)">',
            domainInfo.isSubdomain ? "Subdomain" : "Domain",
            '</text>',
            '<text x="200" y="320" font-family="Arial, sans-serif" font-size="12" ',
            'text-anchor="middle" fill="rgba(255,255,255,0.6)">',
            'Alsania Enhanced Domains',
            '</text>',
            '</svg>'
        ));

        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        ));
    }

    /**
     * @dev Truncates domain name for display
     * @param domain The domain name
     * @param maxLength Maximum length
     * @return truncated The truncated domain
     */
    function _truncateDomain(string memory domain, uint256 maxLength) private pure returns (string memory) {
        bytes memory domainBytes = bytes(domain);
        if (domainBytes.length <= maxLength) {
            return domain;
        }

        bytes memory truncated = new bytes(maxLength - 3);
        for (uint256 i = 0; i < maxLength - 3; i++) {
            truncated[i] = domainBytes[i];
        }

        return string(abi.encodePacked(truncated, "..."));
    }

    /**
     * @dev Gets feature count for a token (placeholder for future enhancements)
     * @param tokenId The token ID
     * @return count The feature count
     */
    function _getFeatureCount(uint256 tokenId) private pure returns (uint256) {
        // Placeholder for future enhancement features
        return 0;
    }

    /**
     * @dev Converts uint256 to string
     * @param value The uint256 value
     * @return The string representation
     */
    function _uintToString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}
