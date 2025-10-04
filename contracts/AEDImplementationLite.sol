// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./external/oz/proxy/utils/UUPSUpgradeable.sol";
import "./external/oz/token/ERC721/ERC721Upgradeable.sol";
import "./external/oz/access/AccessControlUpgradeable.sol";
import "./external/oz/token/ERC721/IERC721Receiver.sol";
import "./core/AppStorage.sol";
import "./libraries/LibAppStorage.sol";
import "./libraries/LibMinting.sol";
import "./libraries/LibAdmin.sol";
import "./libraries/LibMetadata.sol";
import "./libraries/LibReverse.sol";
import "./libraries/LibEnhancements.sol";
import "./core/AEDConstants.sol";

contract AEDImplementationLite is 
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
    
    modifier onlyFeeManager() {
        require(hasRole(FEE_MANAGER_ROLE, msg.sender), "Not fee manager");
        _;
    }
    
    modifier onlyTLDManager() {
        require(hasRole(TLD_MANAGER_ROLE, msg.sender), "Not TLD manager");
        _;
    }
    
    modifier whenNotPaused() {
        require(!LibAppStorage.appStorage().paused, "Contract paused");
        _;
    }
    
    modifier onlyTokenOwner(uint256 tokenId) {
        require(LibAppStorage.appStorage().owners[tokenId] == msg.sender, "Not token owner");
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
        s.admins[admin] = true;
        s.nextTokenId = 1;
        s.baseURI = "https://api.alsania.io/metadata/";
        
        // Initialize default pricing
        s.enhancementPrices["subdomain"] = 2 ether;
        s.enhancementPrices["byo"] = 5 ether;
        s.tldPrices["alsania"] = 1 ether;
        s.tldPrices["fx"] = 1 ether;
        s.tldPrices["echo"] = 1 ether;
        
        // Initialize free TLDs
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
    
    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) 
        internal 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        override 
    {}
    
    // ===== CORE DOMAIN FUNCTIONS =====
    
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool withSubdomains
    ) external payable whenNotPaused returns (uint256) {
        uint256 tokenId = LibMinting.registerDomain(name, tld, withSubdomains);
        _processDomainPayment(tld, withSubdomains);
        return tokenId;
    }
    
    function mintSubdomain(
        uint256 parentId,
        string calldata label
    ) external payable returns (uint256) {
        string memory parentDomain = LibAppStorage.appStorage().tokenIdToDomain[parentId];
        require(bytes(parentDomain).length > 0, "Parent not found");
        
        uint256 tokenId = LibMinting.createSubdomain(label, parentDomain);
        _processSubdomainPayment(parentId);
        return tokenId;
    }
    
    function calculateSubdomainFee(uint256 parentId) external view returns (uint256) {
        return LibMinting.calculateSubdomainFee(parentId);
    }
    
    // ===== METADATA FUNCTIONS =====
    
    function setProfileURI(uint256 tokenId, string calldata uri) external onlyTokenOwner(tokenId) {
        LibMetadata.setProfileURI(tokenId, uri);
    }
    
    function setImageURI(uint256 tokenId, string calldata uri) external onlyTokenOwner(tokenId) {
        LibMetadata.setImageURI(tokenId, uri);
    }
    
    function getProfileURI(uint256 tokenId) external view returns (string memory) {
        return LibMetadata.getProfileURI(tokenId);
    }
    
    function getImageURI(uint256 tokenId) external view returns (string memory) {
        return LibMetadata.getImageURI(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return LibMetadata.tokenURI(tokenId);
    }
    
    // ===== REVERSE RESOLUTION FUNCTIONS =====
    
    function setReverse(string calldata domain) external {
        LibReverse.setReverseRecord(domain);
    }
    
    function clearReverse() external {
        LibReverse.clearReverseRecord();
    }
    
    function getReverse(address addr) external view returns (string memory) {
        return LibAppStorage.appStorage().reverseRecords[addr];
    }
    
    function getReverseOwner(string calldata domain) external view returns (address) {
        return LibAppStorage.appStorage().reverseOwners[domain];
    }
    
    // ===== ENHANCEMENT FUNCTIONS =====
    
    function enableSubdomainFeature(uint256 tokenId) external payable {
        LibEnhancements.enableSubdomains(tokenId);
    }
    
    function getFeaturePrice(string calldata featureName) external view returns (uint256) {
        return LibEnhancements.getFeaturePrice(featureName);
    }
    
    function isFeatureEnabled(uint256 tokenId, string calldata featureName) external view returns (bool) {
        return LibEnhancements.isFeatureEnabled(tokenId, featureName);
    }
    
    // ===== ADMIN FUNCTIONS =====
    
    function updateFee(string calldata feeType, uint256 newAmount) external onlyFeeManager {
        LibAdmin.updateFee(feeType, newAmount);
    }
    
    function updateFeeRecipient(address newRecipient) external onlyAdmin {
        LibAdmin.updateFeeRecipient(newRecipient);
    }
    
    function configureTLD(string calldata tld, bool isActive, uint256 price) external onlyTLDManager {
        LibAdmin.configureTLD(tld, isActive, price);
    }
    
    function pause() external onlyAdmin {
        LibAdmin.pauseContract();
    }
    
    function unpause() external onlyAdmin {
        LibAdmin.unpauseContract();
    }
    
    // ===== VIEW FUNCTIONS =====
    
    function getDomainInfo(uint256 tokenId) external view returns (Domain memory) {
        require(_tokenExists(tokenId), "Token does not exist");
        return LibAppStorage.appStorage().domains[tokenId];
    }
    
    function getUserDomains(address user) external view returns (string[] memory) {
        return LibAppStorage.appStorage().userDomains[user];
    }
    
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
        require(_tokenExists(tokenId), "Token does not exist");
        return LibAppStorage.appStorage().tokenIdToDomain[tokenId];
    }
    
    function getTokenIdByDomain(string calldata domain) external view returns (uint256) {
        uint256 tokenId = LibAppStorage.appStorage().domainToTokenId[domain];
        require(tokenId != 0, "Domain not found");
        return tokenId;
    }
    
    // ===== ERC721 OVERRIDES =====
    
    function ownerOf(uint256 tokenId) public view override returns (address) {
        AppStorage storage s = LibAppStorage.appStorage();
        address owner = s.owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Zero address query");
        return LibAppStorage.appStorage().balances[owner];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _customTransfer(from, to, tokenId);
    }
    
    // ===== INTERNAL FUNCTIONS =====
    
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.appStorage().owners[tokenId] != address(0);
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        address owner = s.owners[tokenId];
        return (spender == owner || 
                s.tokenApprovals[tokenId] == spender || 
                s.operatorApprovals[owner][spender]);
    }
    
    function _customTransfer(address from, address to, uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to zero address");
        
        // Clear approvals and update ownership
        delete s.tokenApprovals[tokenId];
        s.balances[from]--;
        s.balances[to]++;
        s.owners[tokenId] = to;
        s.domains[tokenId].owner = to;
        
        // Update user domain arrays
        string memory domain = s.tokenIdToDomain[tokenId];
        _removeFromUserDomains(from, domain);
        s.userDomains[to].push(domain);
        
        LibReverse.handleDomainTransfer(from, to, domain);
        emit Transfer(from, to, tokenId);
    }
    
    function _removeFromUserDomains(address user, string memory domain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        string[] storage userDomains = s.userDomains[user];
        
        for (uint256 i = 0; i < userDomains.length; i++) {
            if (keccak256(bytes(userDomains[i])) == keccak256(bytes(domain))) {
                userDomains[i] = userDomains[userDomains.length - 1];
                userDomains.pop();
                break;
            }
        }
    }
    
    function _processDomainPayment(string calldata tld, bool withEnhancements) internal {
        uint256 totalCost = _calculateDomainCost(tld, withEnhancements);
        
        require(msg.value >= totalCost, "Insufficient payment");
        LibAppStorage.appStorage().totalRevenue += totalCost;
        
        if (totalCost > 0) {
            payable(LibAppStorage.appStorage().feeCollector).transfer(totalCost);
        }
        
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }
    
    function _processSubdomainPayment(uint256 parentId) internal {
        uint256 cost = LibMinting.calculateSubdomainFee(parentId);
        require(msg.value >= cost, "Insufficient payment");
        
        LibAppStorage.appStorage().totalRevenue += cost;
        
        if (cost > 0) {
            payable(LibAppStorage.appStorage().feeCollector).transfer(cost);
        }
        
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    
    function _calculateDomainCost(string calldata tld, bool withEnhancements) internal view returns (uint256) {
        AppStorage storage store = LibAppStorage.appStorage();
        uint256 totalCost = 0;
        
        if (!store.freeTlds[tld]) {
            totalCost += store.tldPrices[tld];
        }
        
        if (withEnhancements) {
            totalCost += store.enhancementPrices["subdomain"];
        }
        
        return totalCost;
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
