// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibReverse.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDReverse.sol";

abstract contract AEDReverse is ModuleBase, IAEDReverse {
    using LibReverse for AppStorage;
    
    function setReverse(string calldata domain) external override {
        LibReverse.setReverse(domain);
    }
    
    function clearReverse() external override {
        LibReverse.clearReverse();
    }
    
    function getReverse(address addr) external view override returns (string memory) {
        return LibReverse.getReverse(addr);
    }
    
    function getReverseOwner(string calldata domain) external view override returns (address) {
        return LibReverse.getReverseOwner(domain);
    }
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDReverse");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDReverse";
    }
}
