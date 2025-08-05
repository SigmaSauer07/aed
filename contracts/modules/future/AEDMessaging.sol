// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../base/ModuleBase.sol";
import "../../libraries/LibAppStorage.sol";

abstract contract AEDMessaging is ModuleBase {
    using LibAppStorage for AppStorage;
    
    event MessageSent(string indexed fromDomain, string indexed toDomain, bytes32 messageHash);
    
    function sendMessage(
        string calldata fromDomain,
        string calldata toDomain,
        string calldata message
    ) external {
        AppStorage storage s = LibAppStorage.s();
        
        uint256 fromTokenId = s.domainToTokenId[fromDomain];
        require(s.owners[fromTokenId] == msg.sender, "Not domain owner");
        require(s.domainExists[toDomain], "Target domain not found");
        
        bytes32 messageHash = keccak256(abi.encodePacked(message, block.timestamp));
        
        // Store message in future storage slots
        s.futureStringString[string(abi.encodePacked("msg_", fromDomain, "_", toDomain))] = message;
        
        emit MessageSent(fromDomain, toDomain, messageHash);
    }
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDMessaging");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDMessaging";
    }
}