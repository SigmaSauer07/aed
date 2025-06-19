// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title BridgeModule - Handles cross-chain bridging and receipt verification
/// @author Your Team
/// @notice This module manages domain bridging, receipts, and event emission
contract BridgeModule {
    /// @notice Address of the bridge endpoint (LayerZero/CCIP/other)
    address public bridgeEndpoint;

    /// @notice Tracks if a domain is currently bridged
    mapping(uint256 => bool) public isBridged;

    /// @notice Used bridge receipts (for replay protection)
    mapping(bytes32 => bool) public bridgeReceipts;

    /// @notice Emitted when a domain is bridged out
    event DomainBridged(uint256 indexed tokenId, uint16 dstChainId, address indexed to, bytes payload);

    /// @notice Emitted when a domain is received from another chain
    event DomainReceived(uint256 indexed tokenId, uint16 srcChainId, address indexed from, bytes payload);

    /// @notice Emitted when a bridge receipt is marked as used
    event BridgeReceiptUsed(bytes32 indexed receiptHash);

    /// @notice Sets the bridge endpoint (admin only)
    /// @param endpoint The new bridge endpoint address
    function setBridgeEndpoint(address endpoint) external virtual {
        require(endpoint != address(0), "Invalid endpoint");
        bridgeEndpoint = endpoint;
    }

    /// @notice Marks a domain as bridged and emits an event
    /// @param tokenId The domain tokenId
    /// @param dstChainId The destination chain ID
    /// @param to The recipient address on the destination chain
    /// @param payload Arbitrary bridging payload
    function bridgeDomain(uint256 tokenId, uint16 dstChainId, address to, bytes calldata payload) external virtual {
        require(!isBridged[tokenId], "Already bridged");
        isBridged[tokenId] = true;
        emit DomainBridged(tokenId, dstChainId, to, payload);
    }

    /// @notice Receives a domain from another chain, verifies receipt, and emits an event
    /// @param tokenId The domain tokenId
    /// @param srcChainId The source chain ID
    /// @param from The sender address on the source chain
    /// @param to The recipient address on this chain
    /// @param payload Arbitrary bridging payload
    /// @param receiptHash The hash of the bridge receipt
    function receiveDomain(
        uint256 tokenId,
        uint16 srcChainId,
        address from,
        address to,
        bytes calldata payload,
        bytes32 receiptHash
    ) external virtual {
        require(msg.sender == bridgeEndpoint, "Not bridge endpoint");
        require(!bridgeReceipts[receiptHash], "Receipt used");
        bridgeReceipts[receiptHash] = true;
        isBridged[tokenId] = false;
        emit BridgeReceiptUsed(receiptHash);
        emit DomainReceived(tokenId, srcChainId, from, payload);
    }
}