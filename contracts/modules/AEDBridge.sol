// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../core/CoreState.sol";
import "../core/AEDConstants.sol";

/**
 * @title AEDBridge
 * @dev Module for bridging domains to other chains. Allows marking a domain as bridged (locked) and verifying 
 * its transfer to another chain via a Merkle proof.
 */
abstract contract AEDBridge is Initializable, CoreState, AEDConstants {
    event DomainBridged(uint256 indexed tokenId, uint256 indexed destChainId, bytes32 merkleRoot);
    event DomainReceived(uint256 indexed tokenId, address indexed newOwner);

    struct BridgeReceipt {
        uint256 destChainId;
        bytes32 merkleRoot;
        uint256 timestamp;
    }

    mapping(uint256 => BridgeReceipt) public bridgeReceipts;
    mapping(uint256 => bool) public isBridged;

    function __AEDBridge_init() internal onlyInitializing {
        // No specific state to init (placeholder for future)
    }

    function bridgeDomain(uint256 tokenId, uint256 destChainId) external {
        require(hasRole(BRIDGE_MANAGER, msg.sender), "Not authorized");
        require(_exists(tokenId), "Nonexistent token");
        require(!isBridged[tokenId], "Already bridged");

        // Compute a Merkle tree leaf for this bridging event (for off-chain verification on dest chain)
        bytes32 merkleRoot = keccak256(abi.encode(tokenId, destChainId, block.timestamp, ownerOf(tokenId)));

        bridgeReceipts[tokenId] = BridgeReceipt(destChainId, merkleRoot, block.timestamp);
        isBridged[tokenId] = true;

        emit DomainBridged(tokenId, destChainId, merkleRoot);
    }

    function completeBridge(uint256 tokenId, address newOwner, bytes32[] calldata proof) external {
        require(!_exists(tokenId), "Token exists (bridge not completed)");  // tokenId must not exist yet on this chain
        require(newOwner != address(0), "Invalid owner");

        BridgeReceipt storage receipt = bridgeReceipts[tokenId];
        require(receipt.timestamp > 0, "No receipt");  // must have a bridging record

        bytes32 leaf = keccak256(abi.encodePacked(newOwner));
        require(MerkleProof.verify(proof, receipt.merkleRoot, leaf), "Invalid proof");

        // Mint token to newOwner on this chain as completing the bridge
        domains[tokenId].owner = newOwner;
        isBridged[tokenId] = false;
        emit DomainReceived(tokenId, newOwner);
    }

    uint256[50] private __gap;

    function initializeModule_Bridge() public virtual onlyInitializing {
        // Initialization logic for Bridge module (optional)
    }

}
