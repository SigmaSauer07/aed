// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract AEDPricing {
    struct PricingConfig {
        uint256 basePrice;
        uint256 slope;
        uint256 maxFee;
    }
    
    // Pricing per TLD
    mapping(string => PricingConfig) public tldPricing;
    
    constructor() {
        // Set pricing for each TLD
        tldPricing["alsa"] = PricingConfig(0.001 ether, 0.0001 ether, 0.01 ether);
        tldPricing["aed"] = PricingConfig(0.01 ether, 0.0005 ether, 0.1 ether);
        tldPricing["fx"] = PricingConfig(0.005 ether, 0.0003 ether, 0.05 ether);
        tldPricing["07"] = PricingConfig(0.007 ether, 0.0007 ether, 0.07 ether);
        tldPricing["alsania"] = PricingConfig(0.02 ether, 0.001 ether, 0.2 ether);
    }
    
    function getSubdomainPrice(
        string calldata label, 
        string calldata tld
    ) public view returns (uint256) {
        PricingConfig memory config = tldPricing[tld];
        uint256 length = bytes(label).length;
        uint256 calculatedPrice = config.basePrice + (config.slope * length);
        
        return calculatedPrice > config.maxFee ? config.maxFee : calculatedPrice;
    }
    
    function getDomainPrice(
        string calldata name, 
        string calldata tld
    ) public pure returns (uint256) {
        // Domain pricing logic (if different from subdomains)
        return 0.01 ether; // Base domain price
    }
}