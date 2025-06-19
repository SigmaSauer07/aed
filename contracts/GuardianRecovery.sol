// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GuardianRecovery is AccessControlUpgradeable {
    using BitMaps for BitMaps.BitMap;

    struct RecoveryData {
        bytes32 recoveryRoot;
        BitMaps.BitMap approvals;
        address pendingNewOwner;
        uint256 approvalCount;
        uint256 threshold;
    }
    mapping(uint256 => RecoveryData) internal _recovery;

    event GuardianThresholdSet(uint256 indexed tokenId, uint256 threshold);
    event RecoveryInitiated(uint256 indexed tokenId, address indexed newOwner, uint256 approvals);
    event RecoveryFinalized(uint256 indexed tokenId, address indexed newOwner);

    function setRecoveryRoot(uint256 tokenId, bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _recovery[tokenId].recoveryRoot = root;
    }

    function setGuardianThreshold(uint256 tokenId, uint256 threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _recovery[tokenId].threshold = threshold;
        emit GuardianThresholdSet(tokenId, threshold);
    }

    function approveRecovery(uint256 tokenId, address newOwner, bytes32[] calldata merkleProof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _recovery[tokenId].recoveryRoot, leaf), "Invalid proof");
        uint256 idx = uint256(uint160(msg.sender));
        require(!_recovery[tokenId].approvals.get(idx), "Already approved");
        if (_recovery[tokenId].pendingNewOwner != newOwner) {
            _recovery[tokenId].pendingNewOwner = newOwner;
            _recovery[tokenId].approvalCount = 0;
            _recovery[tokenId].approvals = BitMaps.BitMap();
        }
        _recovery[tokenId].approvals.set(idx);
        _recovery[tokenId].approvalCount++;
        emit RecoveryInitiated(tokenId, newOwner, _recovery[tokenId].approvalCount);
    }
}