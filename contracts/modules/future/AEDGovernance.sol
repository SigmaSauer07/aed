// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../base/ModuleBase.sol";
import "../../libraries/LibAppStorage.sol";

abstract contract AEDGovernance is ModuleBase {
    using LibAppStorage for AppStorage;
    
    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event VoteCast(uint256 indexed proposalId, address voter, bool support);
    
    function createProposal(string calldata description) external {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.balances[msg.sender] > 0, "Must own domain to propose");
        
        uint256 proposalId = s.futureUint256[0]++; // Use future storage
        
        emit ProposalCreated(proposalId, msg.sender, description);
    }
    
    function vote(uint256 proposalId, bool support) external {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.balances[msg.sender] > 0, "Must own domain to vote");
        
        // Voting logic using future storage slots
        emit VoteCast(proposalId, msg.sender, support);
    }
}