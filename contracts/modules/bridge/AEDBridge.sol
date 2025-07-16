// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDBridge.sol";

/**
 * @title AEDBridge
 * @dev Module for bridging domains to other chains. Allows marking a domain as bridged (locked) and verifying 
 * its transfer to another chain via cryptographic hash verification.
 */
abstract contract AEDBridge is Initializable, ModuleBase, IAEDBridge {

    event DomainBridged(uint256 indexed tokenId, uint256 indexed destChainId, bytes32 bridgeHash);
    event DomainReceived(uint256 indexed tokenId, address indexed newOwner);

    struct BridgeReceipt {
        uint256 destChainId;
        bytes32 bridgeHash;
        uint256 timestamp;
    }

    mapping(uint256 => BridgeReceipt) public bridgeReceipts;
    mapping(uint256 => bool) public isBridged;

    function __AEDBridge_init() internal onlyInitializing {
        // No specific state to init (placeholder for future)
    }

    function bridgeDomain(uint256 tokenId, string calldata destination) external {
        require(_hasRole(BRIDGE_MANAGER_ROLE, msg.sender), "Not authorized");
        require(_tokenExists(tokenId), "Nonexistent token");
        require(!isBridged[tokenId], "Already bridged");

        // Parse destination chain ID from string (assuming it's a chain ID as string)
        uint256 destChainId = _parseChainId(destination);
        
        // Get token owner
        address tokenOwner = _getTokenOwner(tokenId);
        
        // Create bridge data hash for verification on destination chain
        bytes32 bridgeHash = keccak256(abi.encode(tokenId, destChainId, block.timestamp, tokenOwner));

        bridgeReceipts[tokenId] = BridgeReceipt(destChainId, bridgeHash, block.timestamp);
        isBridged[tokenId] = true;

        emit DomainBridged(tokenId, destChainId, bridgeHash);
    }

    function completeBridge(
        uint256 tokenId, 
        address newOwner, 
        address originalOwner,
        uint256 originalChainId,
        uint256 bridgeTimestamp,
        bytes32 bridgeHash
    ) external {
        require(_hasRole(BRIDGE_MANAGER_ROLE, msg.sender), "Not authorized");
        require(!_tokenExists(tokenId), "Token exists (bridge not completed)");  // tokenId must not exist yet on this chain
        require(newOwner != address(0), "Invalid owner");

        // Verify bridge hash matches the original bridging data
        bytes32 expectedHash = keccak256(abi.encode(tokenId, originalChainId, bridgeTimestamp, originalOwner));
        require(bridgeHash == expectedHash, "Invalid bridge hash");

        // Create bridge receipt for this token on the destination chain
        bridgeReceipts[tokenId] = BridgeReceipt(originalChainId, bridgeHash, block.timestamp);
        
        // Mint token to newOwner on this chain as completing the bridge
        s().domains[tokenId].owner = newOwner;
        isBridged[tokenId] = false;
        emit DomainReceived(tokenId, newOwner);
    }

    function initializeModule_Bridge() public virtual onlyInitializing {
        // Initialization logic for Bridge module (optional)
    }

    // Helper functions
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return s().domains[tokenId].owner != address(0);
    }

    function _getTokenOwner(uint256 tokenId) internal view returns (address) {
        return s().domains[tokenId].owner;
    }

    function _parseChainId(string calldata chainIdStr) internal pure returns (uint256) {
        bytes memory strBytes = bytes(chainIdStr);
        require(strBytes.length > 0, "Invalid chain ID");
        
        uint256 result = 0;
        for (uint256 i = 0; i < strBytes.length; i++) {
            uint8 digit = uint8(strBytes[i]);
            require(digit >= 48 && digit <= 57, "Invalid chain ID format"); // 0-9
            result = result * 10 + (digit - 48);
        }
        return result;
    }

}