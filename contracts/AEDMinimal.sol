// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./core/AppStorage.sol";
import "./libraries/LibAppStorage.sol";
import "./core/AEDConstants.sol";

contract AEDMinimal is 
    UUPSUpgradeable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    AEDConstants
{
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
        string memory domain = LibAppStorage.appStorage().tokenIdToDomain[tokenId];
        return string(abi.encodePacked("https://api.alsania.io/metadata/", domain));
    }
    
    // Admin functions
    function setProfileURI(uint256 tokenId, string calldata uri) external {
        require(LibAppStorage.appStorage().owners[tokenId] == msg.sender, "Not owner");
        LibAppStorage.appStorage().profileURIs[tokenId] = uri;
    }
    
    function setImageURI(uint256 tokenId, string calldata uri) external {
        require(LibAppStorage.appStorage().owners[tokenId] == msg.sender, "Not owner");
        LibAppStorage.appStorage().imageURIs[tokenId] = uri;
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
}
