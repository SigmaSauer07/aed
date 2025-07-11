// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../core/AEDConstants.sol";
import "../core/CoreState.sol";


/**
 * @title AEDAdmin
 * @dev Administrative and configuration module for AED.
 * Includes fee collector, royalties, and contract pause/unpause functionality.
 */
abstract contract AEDAdmin is Initializable, AEDConstants, CoreState {
    // State variables
    struct AdminConfig {
        address feeCollector;
        uint256 royaltyBps;
        uint256 maxSubdomains;
        uint256 basePrice;
        uint256 multiplier;
    }

    AdminConfig internal _admin;

    address public tldManager;
    address public bridgeManager;
    address public domainManager;
    address public subdomainManager;
    address public profileManager;
    address public recoveryManager;
    address public enhancementManager;
    address public metadataManager;

    // Initializer (to be called internally from main initialize)
    function __AEDAdmin_init(address feeCollector) internal onlyInitializing {
        // Note: Core and other base initializers are called in AEDCore and main contract.
        // Here we set up admin-specific state.
        address previousCollector = _admin.feeCollector;
        _admin.maxSubdomains = 20;
        _admin.basePrice = 0.001 ether;
        _admin.multiplier = 2;
        _admin.royaltyBps = 100;  // 1% default royalty (in basis points)
        _admin.feeCollector = feeCollector;
        emit ContractInitialized();
        emit FeeCollectorUpdated(previousCollector, _admin.feeCollector);
        emit RoyaltyUpdated(_admin.royaltyBps);
        emit SubdomainSettingsUpdated(_admin.maxSubdomains, _admin.basePrice, _admin.multiplier);
    }

    // Events
    event ContractInitialized();
    event FeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);
    event TLDManagerUpdated(address indexed oldManager, address indexed newManager);
    event RoyaltyUpdated(uint256 newBps);
    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);
    event EtherWithdrawn(address indexed to, uint256 amount);
    event SubdomainSettingsUpdated(uint256 maxSubdomains, uint256 basePrice, uint256 multiplier);

    // Admin functions
    function setFeeCollector(address newCollector) external {
        require(hasRole(FEE_MANAGER_ROLE, msg.sender), "Not authorized");
        require(newCollector != address(0), "Invalid address");
        require(_admin.feeCollector != newCollector, "Already set to this address");
        address previousCollector = _admin.feeCollector;
        _admin.feeCollector = newCollector;
        emit FeeCollectorUpdated(previousCollector, newCollector);
    }

    function setTLDManager(address newManager) external {
        require(hasRole(TLD_MANAGER_ROLE, msg.sender), "Not authorized");
        require(newManager != address(0), "Invalid address");
        address previousManager = tldManager;
        tldManager = newManager;
        emit TLDManagerUpdated(previousManager, newManager);
    }

    function setRoyaltyBps(uint256 newBps) external {
        require(hasRole(FEE_MANAGER_ROLE, msg.sender), "Not authorized");
        require(newBps <= MAX_ROYALTY_BPS, "Max 10%");
        require(newBps != _admin.royaltyBps, "Already set to this value (10%");
        _admin.royaltyBps = newBps;
        emit RoyaltyUpdated(newBps);
    }

    function pauseContract() external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        emit ContractPaused(msg.sender);
    }   

    function unpauseContract() external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        emit ContractUnpaused(msg.sender);
    }

    function withdrawStuckETH(address payable to) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        require(to != address(0), "Invalid recipient");
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH");
        (bool success, ) = to.call{value: balance}("");
        require(success, "Transfer failed");
        emit EtherWithdrawn(to, balance);
    }

    // Update global subdomain settings (virtual, overridden in main AED to sync with Minting)
    function updateSubdomainSettings(uint256 newMaxSubdomains, uint256 newBasePrice, uint256 newMultiplier) 
        external virtual 
    {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        require(newMaxSubdomains > 0, "Max subdomains must be > 0");
        _admin.maxSubdomains = newMaxSubdomains;
        _admin.basePrice = newBasePrice;
        _admin.multiplier = newMultiplier;
        emit SubdomainSettingsUpdated(newMaxSubdomains, newBasePrice, newMultiplier);
    }

    uint256[50] private __gap;

    function initializeModule_Admin() public virtual onlyInitializing {
        // Initialization logic for Admin module (optional)
    }

}
