// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./DomainRegistry.sol";
import "./SubdomainManager.sol";
import "./GuardianRecovery.sol";
import "./FeeManager.sol";
import "./BridgeModule.sol";

contract AlsaniaDomainSystem is
    DomainRegistry,
    SubdomainManager,
    GuardianRecovery,
    FeeManager,
    BridgeModule
{
    // --- DOMAIN MANAGEMENT ---
    // Override mintDomain to wire up all features, including PaymentSplitter, resolver, content hash, etc.

    function mintDomain(
        address recipient,
        uint256 tokenId,
        string calldata uri,
        string calldata imageURI,
        address[] calldata payees,
        uint256[] calldata shares
    ) public override {
        // Mint the domain NFT
        super.mintDomain(recipient, tokenId, uri, imageURI, payees, shares);

        // Additional logic for AlsaniaDomainSystem can be added here
    }

    // --- SUBDOMAIN MANAGEMENT ---
    // Use SubdomainManager as before

    // --- GUARDIAN RECOVERY ---
    function approveRecovery(uint256 tokenId, address newOwner, bytes32[] calldata merkleProof) public override {
        GuardianRecovery.approveRecovery(tokenId, newOwner, merkleProof);
        if (_recovery[tokenId].approvalCount >= _recovery[tokenId].threshold) {
            _transfer(ownerOf(tokenId), newOwner, tokenId);
            emit RecoveryFinalized(tokenId, newOwner);
        }
    }

    // --- BRIDGING ---
    // Add bridgeDomain/receiveDomain logic using receipts and Merkle proofs
    function bridgeDomain(uint256 tokenId, uint16 dstChainId, address to, bytes calldata payload) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(!isBridged[tokenId], "Already bridged");
        isBridged[tokenId] = true;
        emit DomainBridged(tokenId, dstChainId, to, payload);
    }

    function receiveDomain(
        uint256 tokenId,
        uint16 srcChainId,
        address from,
        address to,
        bytes calldata payload,
        bytes32 receiptHash,
        bytes32[] calldata merkleProof
    ) external {
        require(msg.sender == bridgeEndpoint, "Not bridge endpoint");
        require(!bridgeReceipts[receiptHash], "Receipt used");
        // Optionally: verify Merkle proof for cross-chain state
        // require(MerkleProof.verify(merkleProof, someRoot, receiptHash), "Invalid bridge proof");
        bridgeReceipts[receiptHash] = true;
        isBridged[tokenId] = false;
        if (!_exists(tokenId)) {
            _mint(to, tokenId);
        } else {
            _transfer(ownerOf(tokenId), to, tokenId);
        }
        emit DomainReceived(tokenId, srcChainId, from, payload);
    }

    // --- AI AUTOMATION ---
    bytes32 public constant AI_AGENT_ROLE = keccak256("AI_AGENT_ROLE");

    struct ChainTask {
        address proposer;
        string description;
        bytes data;
        uint256 deadline;
        bool executed;
    }
    mapping(bytes32 => ChainTask) public aiTasks;

    event AITaskProposed(bytes32 indexed taskId, address indexed proposer, string description);
    event AITaskExecuted(bytes32 indexed taskId, address indexed executor);

    function proposeAITask(string calldata description, bytes calldata data, uint256 deadline) external onlyRole(AI_AGENT_ROLE) {
        bytes32 taskId = keccak256(abi.encodePacked(description, data, deadline, block.timestamp, msg.sender));
        aiTasks[taskId] = ChainTask({
            proposer: msg.sender,
            description: description,
            data: data,
            deadline: deadline,
            executed: false
        });
        emit AITaskProposed(taskId, msg.sender, description);
    }

    function executeAITask(bytes32 taskId) external onlyRole(AI_AGENT_ROLE) {
        ChainTask storage task = aiTasks[taskId];
        require(!task.executed, "Already executed");
        require(block.timestamp <= task.deadline, "Task expired");
        // Custom logic for AI task execution goes here
        task.executed = true;
        emit AITaskExecuted(taskId, msg.sender);
    }

    // --- META-TX, PAUSABLE, ADMIN TRANSFER ---
    // Implement as in DomainRegistry

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // --- BATCH OPS ---
    function batchMintDomains(
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        string[] calldata uris,
        string[] calldata imageURIs,
        address[][] calldata payees,
        uint256[][] calldata shares
    ) external onlyRole(ADMIN_ROLE) {
        require(
            recipients.length == tokenIds.length &&
            recipients.length == uris.length &&
            recipients.length == imageURIs.length &&
            recipients.length == payees.length &&
            recipients.length == shares.length,
            "Array length mismatch"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            mintDomain(recipients[i], tokenIds[i], uris[i], imageURIs[i], payees[i], shares[i]);
        }
    }

    function batchCreateSubdomains(
        string[] calldata names,
        uint256[] calldata parentTokenIds,
        address[] calldata owners,
        string[] calldata profileURIs,
        string[] calldata imageURIs
    ) external payable {
        require(
            names.length == parentTokenIds.length &&
            names.length == owners.length &&
            names.length == profileURIs.length &&
            names.length == imageURIs.length,
            "Array length mismatch"
        );
        for (uint256 i = 0; i < names.length; i++) {
            createSubdomain(names[i], parentTokenIds[i], owners[i], profileURIs[i], imageURIs[i]);
        }
    }
}