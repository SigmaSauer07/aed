// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./core/AppStorage.sol";
import "./libraries/LibAppStorage.sol";
import "./core/AEDConstants.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AEDMinimal is 
    UUPSUpgradeable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    AEDConstants
{
    // ERC-4906 metadata update events for marketplaces
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    using LibAppStorage for AppStorage;
    
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }
    
    modifier whenNotPaused() {
        require(!LibAppStorage.appStorage().paused, "Contract paused");
        _;
    }
    
    function initialize(
        string memory name,
        string memory symbol,
        address paymentWallet,
        address admin
    ) public initializer {
        __ERC721_init(name, symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        
        AppStorage storage s = LibAppStorage.appStorage();
        s.feeCollector = paymentWallet;
        s.nextTokenId = 1;
        
        // Initialize default pricing
        s.enhancementPrices["subdomain"] = 2 ether;
        s.tldPrices["alsania"] = 1 ether;
        s.tldPrices["fx"] = 1 ether;
        s.tldPrices["echo"] = 1 ether;
        
        // Initialize TLDs
        s.freeTlds["aed"] = true;
        s.freeTlds["alsa"] = true;
        s.freeTlds["07"] = true;
        s.validTlds["aed"] = true;
        s.validTlds["alsa"] = true;
        s.validTlds["07"] = true;
        s.validTlds["alsania"] = true;
        s.validTlds["fx"] = true;
        s.validTlds["echo"] = true;
    }
    
    function _authorizeUpgrade(address) internal onlyRole(DEFAULT_ADMIN_ROLE) override {}
    

    
    // Core domain registration
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool withSubdomains
    ) external payable whenNotPaused returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.validTlds[tld], "Invalid TLD");
        
        string memory fullDomain = string(abi.encodePacked(name, ".", tld));
        require(!s.domainExists[fullDomain], "Domain exists");
        
        uint256 tokenId = s.nextTokenId++;
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        s.domainToTokenId[fullDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullDomain;
        s.domainExists[fullDomain] = true;
        s.userDomains[msg.sender].push(fullDomain);
        
        s.domains[tokenId] = Domain({
            name: name,
            tld: tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: false,
            owner: msg.sender
        });
        
        if (withSubdomains) {
            s.domainFeatures[tokenId] |= 1; // FEATURE_SUBDOMAINS
        }
        
        // Handle payment
        uint256 cost = _calculateCost(tld, withSubdomains);
        require(msg.value >= cost, "Insufficient payment");
        if (cost > 0) {
            payable(s.feeCollector).transfer(cost);
        }
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
        
        emit Transfer(address(0), msg.sender, tokenId);
        return tokenId;
    }
    
    // Subdomain creation
    function mintSubdomain(uint256 parentId, string calldata label) external payable returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[parentId] == msg.sender, "Not owner");
        require((s.domainFeatures[parentId] & 1) != 0, "Subdomains not enabled");
        
        string memory parentDomain = s.tokenIdToDomain[parentId];
        string memory subdomainName = string(abi.encodePacked(label, ".", parentDomain));
        require(!s.domainExists[subdomainName], "Subdomain exists");
        
        uint256 tokenId = s.nextTokenId++;
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        s.domainToTokenId[subdomainName] = tokenId;
        s.tokenIdToDomain[tokenId] = subdomainName;
        s.domainExists[subdomainName] = true;
        s.userDomains[msg.sender].push(subdomainName);
        
        s.domains[tokenId] = Domain({
            name: label,
            tld: parentDomain,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: true,
            owner: msg.sender
        });
        
        s.domains[parentId].subdomainCount++;
        
        uint256 cost = _calculateSubdomainFee(parentId);
        require(msg.value >= cost, "Insufficient payment");
        if (cost > 0) {
            payable(s.feeCollector).transfer(cost);
        }
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
        
        emit Transfer(address(0), msg.sender, tokenId);
        return tokenId;
    }
    
    // View functions
    function getFeeCollector() external view returns (address) {
        return LibAppStorage.appStorage().feeCollector;
    }
    
    function isTLDActive(string calldata tld) external view returns (bool) {
        return LibAppStorage.appStorage().validTlds[tld];
    }
    
    function isRegistered(string calldata name, string calldata tld) external view returns (bool) {
        string memory fullDomain = string(abi.encodePacked(name, ".", tld));
        return LibAppStorage.appStorage().domainExists[fullDomain];
    }
    
    function getDomainByTokenId(uint256 tokenId) external view returns (string memory) {
        return LibAppStorage.appStorage().tokenIdToDomain[tokenId];
    }
    
    function getTokenIdByDomain(string calldata domain) external view returns (uint256) {
        return LibAppStorage.appStorage().domainToTokenId[domain];
    }
    
    function getUserDomains(address user) external view returns (string[] memory) {
        return LibAppStorage.appStorage().userDomains[user];
    }
    
    function getDomainInfo(uint256 tokenId) external view returns (Domain memory) {
        require(LibAppStorage.appStorage().owners[tokenId] != address(0), "Token does not exist");
        return LibAppStorage.appStorage().domains[tokenId];
    }
    
    function getFeaturePrice(string calldata feature) external view returns (uint256) {
        return LibAppStorage.appStorage().enhancementPrices[feature];
    }
    
    function isFeatureEnabled(uint256 tokenId, string calldata feature) external view returns (bool) {
        if (keccak256(bytes(feature)) == keccak256("subdomain")) {
            return (LibAppStorage.appStorage().domainFeatures[tokenId] & 1) != 0;
        }
        return false;
    }
    
    function calculateSubdomainFee(uint256 parentId) external view returns (uint256) {
        return _calculateSubdomainFee(parentId);
    }
    
    // ERC721 overrides
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = LibAppStorage.appStorage().owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Zero address");
        return LibAppStorage.appStorage().balances[owner];
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(LibAppStorage.appStorage().owners[tokenId] != address(0), "Token does not exist");
        AppStorage storage s = LibAppStorage.appStorage();

        // 1) Per-token override (e.g., ipfs://CID/123.json or https://host/123.json)
        if (bytes(s.tokenURIs[tokenId]).length > 0) {
            return s.tokenURIs[tokenId];
        }
        // Preload info for path logic
        string memory domain = s.tokenIdToDomain[tokenId];
        Domain memory domainInfo = s.domains[tokenId];

        // 2) External base URI configured: return baseURI + (domain|sub)/<tokenId>.json
        if (bytes(s.baseURI).length > 0) {
            string memory folder = domainInfo.isSubdomain ? "sub/" : "domain/";
            return string(abi.encodePacked(s.baseURI, folder, _toString(tokenId), ".json"));
        }

        // 3) Fallback: on-chain base64 JSON (wallets that support data: URIs)

        // Choose default image if none set
        string memory imageURI = bytes(s.imageURIs[tokenId]).length > 0
            ? s.imageURIs[tokenId]
            : (domainInfo.isSubdomain
                ? "https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png"
                : "https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png");

        string memory json = string(abi.encodePacked(
            '{"name":"', domain, '",',
            '"description":"Alsania Enhanced Domain - ', domain, '",',
            '"image":"', imageURI, '",',
            '"external_url":"https://alsania.io/domain/', domain, '",',
            '"attributes":[',
                '{"trait_type":"TLD","value":"', domainInfo.tld, '"},',
                '{"trait_type":"Subdomains","value":', _toString(domainInfo.subdomainCount), '},',
                '{"trait_type":"Type","value":"', domainInfo.isSubdomain ? "Subdomain" : "Domain", '"},',
                '{"trait_type":"Features Enabled","value":', _toString(_getFeatureCount(tokenId)), '}',
            ']}'
        ));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // Admin: set external baseURI (e.g., https://gateway.pinata.cloud/ipfs/<CID>/ )
    function setBaseURI(string calldata newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        LibAppStorage.appStorage().baseURI = newBaseURI;
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    // Admin: set per-token URI override
    function setTokenURI(uint256 tokenId, string calldata newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(LibAppStorage.appStorage().owners[tokenId] != address(0), "Token does not exist");
        LibAppStorage.appStorage().tokenURIs[tokenId] = newURI;
        emit MetadataUpdate(tokenId);
    }
    
    // Admin functions
    function setProfileURI(uint256 tokenId, string calldata uri) external {
        require(LibAppStorage.appStorage().owners[tokenId] == msg.sender, "Not owner");
        LibAppStorage.appStorage().profileURIs[tokenId] = uri;
        emit MetadataUpdate(tokenId);
    }
    
    function setImageURI(uint256 tokenId, string calldata uri) external {
        require(LibAppStorage.appStorage().owners[tokenId] == msg.sender, "Not owner");
        LibAppStorage.appStorage().imageURIs[tokenId] = uri;
        emit MetadataUpdate(tokenId);
    }
    
    function setReverse(string calldata domain) external {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 tokenId = s.domainToTokenId[domain];
        require(s.owners[tokenId] == msg.sender, "Not owner");
        s.reverseRecords[msg.sender] = domain;
    }
    
    function getReverse(address addr) external view returns (string memory) {
        return LibAppStorage.appStorage().reverseRecords[addr];
    }
    
    function enableSubdomainFeature(uint256 tokenId) external payable {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] == msg.sender, "Not owner");
        
        uint256 cost = s.enhancementPrices["subdomain"];
        require(msg.value >= cost, "Insufficient payment");
        
        s.domainFeatures[tokenId] |= 1; // FEATURE_SUBDOMAINS
        
        if (cost > 0) {
            payable(s.feeCollector).transfer(cost);
        }
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    
    function pause() external onlyAdmin {
        LibAppStorage.appStorage().paused = true;
    }
    
    function unpause() external onlyAdmin {
        LibAppStorage.appStorage().paused = false;
    }
    
    // Internal functions
    function _calculateCost(string calldata tld, bool withSubdomains) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 cost = 0;
        if (!s.freeTlds[tld]) {
            cost += s.tldPrices[tld];
        }
        if (withSubdomains) {
            cost += s.enhancementPrices["subdomain"];
        }
        return cost;
    }
    
    function _calculateSubdomainFee(uint256 parentId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 subdomainCount = s.domains[parentId].subdomainCount;
        if (subdomainCount < 2) return 0;
        return 0.1 ether * (2 ** (subdomainCount - 2));
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // Helper functions for metadata
    function _generateDefaultImage(string memory domain, bool isSubdomain) internal pure returns (string memory) {
    // Alsania brand colors
    // Midnight Navy (Core Background): #0A2472
        // Neon Green (Core Accent): #39FF14
        string memory bgColor = isSubdomain ? "#071A52" : "#0A2472"; // darker blue for subdomains, core navy for domains
        string memory textColor = "#39FF14"; // Neon green (brand)
    
    string memory svg = string(abi.encodePacked(
    '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
    '<rect width="400" height="400" fill="', bgColor, '"/>',
    '<rect x="20" y="20" width="360" height="360" fill="none" stroke="', textColor, '" stroke-width="2"/>',
    '<text x="200" y="180" font-family="monospace" font-size="16" font-weight="bold" text-anchor="middle" fill="', textColor, '">',
    _truncateString(domain, 24),
    '</text>',
    '<text x="200" y="220" font-family="monospace" font-size="12" text-anchor="middle" fill="', textColor, '">',
    isSubdomain ? "Subdomain" : "Domain",
    '</text>',
    '<text x="200" y="250" font-family="monospace" font-size="10" text-anchor="middle" fill="#888">',
    'Alsania Enhanced Domain',
    '</text>',
    '</svg>'
    ));
    
    return string(abi.encodePacked(
        "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        ));
    }
    
    function _getFeatureCount(uint256 tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 features = s.domainFeatures[tokenId];
        uint256 count = 0;
        
        // Count bits set in features
        while (features > 0) {
            if (features & 1 == 1) {
                count++;
            }
            features >>= 1;
        }
        
        return count;
    }
    
    function _toString(uint256 value) internal pure returns (string memory) {
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
    
    function _truncateString(string memory str, uint256 maxLength) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length <= maxLength) {
            return str;
        }
        
        bytes memory truncated = new bytes(maxLength - 3);
        for (uint256 i = 0; i < maxLength - 3; i++) {
            truncated[i] = strBytes[i];
        }
        
        return string(abi.encodePacked(truncated, "..."));
    }
    

}
