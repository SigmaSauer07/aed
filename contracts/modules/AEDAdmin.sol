// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/CoreState.sol";
import "../core/AEDConstants.sol";


abstract contract AEDAdmin is CoreState, AEDConstants {
    
    // State variables
    struct AdminConfig {
        address feeCollector;
        uint256 royaltyBps;
        uint256 maxSubdomains;
        uint256 basePrice;
        uint256 multiplier;

    AdminConfig internal _admin;

    address public tldManager;  // Address of the TLD manager
    address public bridgeManager;   // Address of the bridge manager
    address public domainManager;   // Address of the domain manager
    address public subdomainManager;   // Address of the subdomain manager
    address public profileManager;   // Address of the profile manager
    address public recoveryManager;   // Address of the recovery manager
    address public enhancementManager;   // Address of the enhancement manager
    address public metadataManager;   // Address of the metadata manager

    // Initializer
    function __AEDAdmin_init() internal {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        __AEDCore_init("Alsania Enhanced Domains", "AED");
        __AEDAdmin_init_();
        __ERC721_init(name_, symbol_);
        emit ContractInitialized();
        address previousCollector = _admin.feeCollector;
        uint256 previousRoyaltyBps = _admin.royaltyBps;
        _admin.maxSubdomains = 20;
        _admin.basePrice = 0.001 ether;
        _admin.multiplier = 2;
        _admin.royaltyBps = 100; // 1% royalty by default
        _admin.feeCollector = msg.sender; // Set initial fee collector to contract deployer
        emit FeeCollectorUpdated(previousCollector, _admin.feeCollector);
        emit RoyaltyUpdated(_admin.royaltyBps);
        emit SubdomainSettingsUpdated(
            _admin.maxSubdomains,
            _admin.basePrice,
            _admin.multiplier
        );
    }

    // Events
    event FeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);
    event TLDManagerUpdated(address indexed oldManager, address indexed newManager);
    event RoyaltyUpdated(uint256 newBps);
    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);
    event EtherWithdrawn(address indexed to, uint256 amount);
    event SubdomainSettingsUpdated(uint256 maxSubdomains, uint256 basePrice, uint256 multiplier);

    // Functions
    function setFeeCollector(address newCollector) external hasRole(FEE_MANAGER_ROLE) {
        require(newCollector != address(0), "Invalid address");
        require(_admin.feeCollector != newCollector, "Already set to this address");
        address previousCollector = _admin.feeCollector;
        _admin.feeCollector = newCollector;
        emit FeeCollectorUpdated(previousCollector, newCollector);
    }

    function setTLDManager(address newManager) external hasRole(TLD_MANAGER_ROLE) {
        require(newManager != address(0), "Invalid address");
        address previousManager = tldManager;
        tldManager = newManager;
        emit TLDManagerUpdated(previousManager, newManager);
    }

    function setRoyaltyBps(uint256 newBps) external hasRole(FEE_MANAGER_ROLE) {
        require(newBps <= MAX_ROYALTY_BPS, "Max 10%");
        _admin.royaltyBps = newBps;
        emit RoyaltyUpdated(newBps);
    }

    function pauseContract() external hasRole(ADMIN_ROLE) {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external hasRole(ADMIN_ROLE) {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function withdrawStuckETH(address payable to) external hasRole(ADMIN_ROLE)  {
        require(to != address(0), "Invalid recipient");
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH");
        (bool success, ) = to.call{value: balance}("");
        require(success, "Transfer failed");
        emit EtherWithdrawn(to, balance);
    }

    function updateSubdomainSettings(uint256 newMaxSubdomains, uint256 newBasePrice, uint256 newMultiplier) external hasRole(ADMIN_ROLE) {
        require(newMaxSubdomains > 0, "Max subdomains must be > 0");
        require(newBasePrice >= 0, "Base price cannot be negative");
        require(newMultiplier >= 0, "Multiplier cannot be negative");

        _admin.maxSubdomains = newMaxSubdomains;
        _admin.basePrice = newBasePrice;
        _admin.multiplier = newMultiplier;

        emit SubdomainSettingsUpdated(newMaxSubdomains, newBasePrice, newMultiplier);
    }

    //gap for future upgrades
    uint256[50] private __gap;
    
}