// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibReverse.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDReverse.sol";

abstract contract AEDReverse is ModuleBase, IAEDReverse {
    using LibAppStorage for AppStorage;
    
    function setReverse(string calldata domain) external override {
        LibReverse.setReverseRecord(domain);
    }
    
    function clearReverse() external override {
        LibReverse.clearReverseRecord();
    }
    
    function getReverse(address addr) external view override returns (string memory) {
        return LibReverse.getPrimaryDomain(addr);
    }
    
    function getReverseOwner(string calldata domain) external view override returns (address) {
        return LibReverse.getDomainPrimaryOwner(domain);
    }
    
    function setReverseFor(address addr, string calldata domain) external onlyAdmin {
        LibReverse.setReverseRecordFor(addr, domain);
    }
    
    function hasReverse(address addr) external view returns (bool) {
        return LibReverse.hasReverseRecord(addr);
    }
    
    function isDomainPrimary(string calldata domain) external view returns (bool) {
        return LibReverse.isDomainPrimary(domain);
    }
    
    function getOwnedDomains(address addr) external view returns (string[] memory) {
        return LibReverse.getOwnedDomains(addr);
    }
    
    function resolveAddress(address addr) external view returns (string memory) {
        return LibReverse.resolveAddress(addr);
    }
    
    function batchResolveAddresses(address[] calldata addresses) external view returns (string[] memory) {
        return LibReverse.batchResolveAddresses(addresses);
    }
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDReverse");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDReverse";
    }
    
    function getSelectors() external pure override returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](10);
        selectors[0] = this.setReverse.selector;
        selectors[1] = this.clearReverse.selector;
        selectors[2] = this.getReverse.selector;
        selectors[3] = this.getReverseOwner.selector;
        selectors[4] = this.setReverseFor.selector;
        selectors[5] = this.hasReverse.selector;
        selectors[6] = this.isDomainPrimary.selector;
        selectors[7] = this.getOwnedDomains.selector;
        selectors[8] = this.resolveAddress.selector;
        selectors[9] = this.batchResolveAddresses.selector;
        return selectors;
    }
}
