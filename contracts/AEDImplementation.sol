// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./core/AppStorage.sol";
import "./libraries/LibAppStorage.sol";
import "./libraries/LibMinting.sol";
import "./libraries/LibAdmin.sol";
import "./libraries/LibMetadata.sol";
import "./libraries/LibReverse.sol";
import "./libraries/LibEnhancements.sol";
import "./core/AEDConstants.sol";

contract AEDImplementation is 
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
    
    // ===== DOMAIN MINTING FUNCTIONS =====
    
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
    
    function batchRegisterDomains(
        string[] calldata names,
        string[] calldata tlds,
        bool[] calldata withSubdomains
    ) external payable returns (uint256[] memory) {
        uint256[] memory tokenIds = LibMinting.batchRegisterDomains(names, tlds, withSubdomains);
        
        // Calculate and process batch payment
        uint256 totalCost = 0;
        for (uint256 i = 0; i < names.length; i++) {
            totalCost += _calculateDomainCost(tlds[i], withSubdomains[i]);
        }
        
        require(msg.value >= totalCost, "Insufficient payment");
        LibAppStorage.appStorage().totalRevenue += totalCost;
        
        // Send to fee collector
        if (totalCost > 0) {
            payable(LibAppStorage.appStorage().feeCollector).transfer(totalCost);
        }
        
        // Refund excess
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        return tokenIds;
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
    
    function purchaseFeature(uint256 tokenId, string calldata featureName) external payable {
        LibEnhancements.purchaseFeature(tokenId, featureName);
    }
    
    function enableSubdomainFeature(uint256 tokenId) external payable {
        LibEnhancements.enableSubdomains(tokenId);
    }
    
    function upgradeExternalDomain(string calldata externalDomain) external payable {
        LibEnhancements.upgradeExternalDomain(externalDomain);
    }
    
    function getFeaturePrice(string calldata featureName) external view returns (uint256) {
        return LibEnhancements.getFeaturePrice(featureName);
    }
    
    function isFeatureEnabled(uint256 tokenId, string calldata featureName) external view returns (bool) {
        return LibEnhancements.isFeatureEnabled(tokenId, featureName);
    }
    
    function getAvailableFeatures() external view returns (string[] memory) {
        return LibEnhancements.getAvailableFeatures();
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
    
    function setFeaturePrice(string calldata featureName, uint256 price) external onlyAdmin {
        LibEnhancements.setFeaturePrice(featureName, price);
    }
    
    function addFeature(string calldata featureName, uint256 price, uint256 flag) external onlyAdmin {
        LibEnhancements.addFeature(featureName, price, flag);
    }
    
    function pause() external onlyAdmin {
        LibAdmin.pauseContract();
    }
    
    function unpause() external onlyAdmin {
        LibAdmin.unpauseContract();
    }
    
    // Override role functions to use our library
    function grantRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.grantRole(role, account);
        LibAdmin.grantRole(role, account);
    }
    
    function revokeRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.revokeRole(role, account);
        LibAdmin.revokeRole(role, account);
    }
    
    // ===== VIEW FUNCTIONS =====
    
    function getDomainInfo(uint256 tokenId) external view returns (Domain memory) {
        require(_tokenExists(tokenId), "Token does not exist");
        return LibAppStorage.appStorage().domains[tokenId];
    }
    
    function getUserDomains(address user) external view returns (string[] memory) {
        return LibAppStorage.appStorage().userDomains[user];
    }
    
    function getTotalRevenue() external view returns (uint256) {
        return LibAppStorage.appStorage().totalRevenue;
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
    
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Not owner nor approved"
        );
        
        _approve(to, tokenId);
    }
    
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_tokenExists(tokenId), "Token does not exist");
        return LibAppStorage.appStorage().tokenApprovals[tokenId];
    }
    
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Approve to caller");
        _setApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return LibAppStorage.appStorage().operatorApprovals[owner][operator];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _customTransfer(from, to, tokenId);
    }
    
    function safeTransferFromSingle(address from, address to, uint256 tokenId) public {
        safeTransferFromWithData(from, to, tokenId, "");
    }
    
    function safeTransferFromWithData(address from, address to, uint256 tokenId, bytes memory data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _customSafeTransfer(from, to, tokenId, data);
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
        
        // Clear approvals
        delete s.tokenApprovals[tokenId];
        
        // Update balances
        s.balances[from]--;
        s.balances[to]++;
        s.owners[tokenId] = to;
        
        // Update domain owner
        s.domains[tokenId].owner = to;
        
        // Update user domain arrays
        string memory domain = s.tokenIdToDomain[tokenId];
        _removeFromUserDomains(from, domain);
        s.userDomains[to].push(domain);
        
        // Handle reverse resolution updates
        LibReverse.handleDomainTransfer(from, to, domain);
        
        emit Transfer(from, to, tokenId);
    }
    
    function _approve(address to, uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    
    function _setApprovalForAll(address owner, address operator, bool approved) internal override {
        require(owner != operator, "Approve to caller");
        AppStorage storage s = LibAppStorage.appStorage();
        s.operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    
    function _customSafeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _customTransfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "Transfer to non ERC721Receiver");
    }
    
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non ERC721Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    function _removeFromUserDomains(address user, string memory domain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        string[] storage userDomains = s.userDomains[user];
        
        for (uint256 i = 0; i < userDomains.length; i++) {
            if (keccak256(bytes(userDomains[i])) == keccak256(bytes(domain))) {
                // Move last element to current position and pop
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
        
        // Send to fee collector
        if (totalCost > 0) {
            payable(LibAppStorage.appStorage().feeCollector).transfer(totalCost);
        }
        
        // Refund excess
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }
    
    function _processSubdomainPayment(uint256 parentId) internal {
        uint256 cost = LibMinting.calculateSubdomainFee(parentId);
        require(msg.value >= cost, "Insufficient payment");
        
        LibAppStorage.appStorage().totalRevenue += cost;
        
        // Send to fee collector
        if (cost > 0) {
            payable(LibAppStorage.appStorage().feeCollector).transfer(cost);
        }
        
        // Refund excess
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    
    function _calculateDomainCost(string calldata tld, bool withEnhancements) internal view returns (uint256) {
        AppStorage storage store = LibAppStorage.appStorage();
        uint256 totalCost = 0;
        
        // Add TLD cost
        if (!store.freeTlds[tld]) {
            totalCost += store.tldPrices[tld];
        }
        
        // Add enhancement cost
        if (withEnhancements) {
            totalCost += store.enhancementPrices["subdomain"];
        }
        
        return totalCost;
    }
    
    // Support interface detection
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
