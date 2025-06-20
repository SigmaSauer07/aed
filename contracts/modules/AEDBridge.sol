// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AEDCore.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract AEDBridge is AEDCore {
    function bridgeDomain(uint256 id, uint256 dest) external onlyRole(BRIDGE_MANAGER) {
        bridgeReceipts[id] = BridgeReceipt(dest, keccak256(abi.encode(id,dest,block.timestamp)), block.timestamp);
        isBridged[id] = true;
        emit BridgeInitiated(id, dest);
    }
    function verifyBridge(uint256 id, address newOwner, bytes32[] calldata proof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(newOwner));
        return MerkleProof.verify(proof, bridgeReceipts[id].merkleRoot, leaf);
    }
}
