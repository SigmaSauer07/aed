// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/CoreState.sol";
import "../core/AEDConstants.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract AEDBridge is CoreState, AEDConstants {
    event DomainBridged(uint256 indexed tokenId, uint256 indexed destChainId, bytes32 merkleRoot);
    event DomainReceived(uint256 indexed tokenId, address indexed newOwner);

    struct BridgeReceipt {
        uint256 destChainId;
        bytes32 merkleRoot;
        uint256 timestamp;
    }

    mapping(uint256 => BridgeReceipt) public bridgeReceipts;
    mapping(uint256 => bool) public isBridged;

    function __AEDBridge_init() internal {}

    function bridgeDomain(uint256 tokenId, uint256 destChainId) external {
        require(hasRole(BRIDGE_MANAGER, msg.sender), "Not authorized");
        require(_exists(tokenId), "Nonexistent token");
        require(!isBridged[tokenId], "Already bridged");

        bytes32 merkleRoot = keccak256(abi.encode(
            tokenId, destChainId, block.timestamp, ownerOf(tokenId)
        ));

        bridgeReceipts[tokenId] = BridgeReceipt(destChainId, merkleRoot, block.timestamp);
        isBridged[tokenId] = true;

        emit DomainBridged(tokenId, destChainId, merkleRoot);
    }

    function completeBridge(uint256 tokenId, address newOwner, bytes32[] calldata proof) external {
        require(!_exists(tokenId), "Token exists");
        require(newOwner != address(0), "Invalid owner");

        BridgeReceipt storage receipt = bridgeReceipts[tokenId];
        require(receipt.timestamp > 0, "No receipt");

        bytes32 leaf = keccak256(abi.encodePacked(newOwner));
        require(MerkleProof.verify(proof, receipt.merkleRoot, leaf), "Invalid proof");

        domains[tokenId].owner = newOwner;
        isBridged[tokenId] = false;

        emit DomainReceived(tokenId, newOwner);
    }

    uint256[50] private __gap;
}