// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/CoreState.sol";
import "../core/AEDConstants.sol";

abstract contract AEDRecovery is CoreState {

    event GuardianAdded(uint256 indexed tokenId, address indexed guardian);
    event GuardianRemoved(uint256 indexed tokenId, address indexed guardian);
    event RecoveryInitiated(uint256 indexed tokenId, uint256 unlockTime);
    event RecoveryCompleted(uint256 indexed tokenId, address indexed newOwner);
    event RecoveryCanceled(uint256 indexed tokenId);
    event RecoveryApproved(uint256 indexed tokenId, address indexed guardian);
    event RecoveryApprovalThresholdChanged(uint256 oldThreshold, uint256 newThreshold);

    uint256 public recoveryApprovalThreshold;
    uint256 public recoveryLockDuration;

    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _guardians;
    mapping(uint256 => uint256) public recoveryTimestamps;
    mapping(uint256 => mapping(address => bool)) public recoveryApprovals;
    mapping(uint256 => uint256) public recoveryApprovalCounts;
    mapping(address => uint256) private _guardianToTokenId;

    function __AEDRecovery_init(uint256 maxGuardians, uint256 approvalThreshold) internal onlyInitializing {
        MAX_GUARDIANS = maxGuardians;
        recoveryApprovalThreshold = approvalThreshold;
    }

    function setRecoveryApprovalThreshold(uint256 newThreshold) external onlyOwner {
        uint256 oldThreshold = recoveryApprovalThreshold;
        recoveryApprovalThreshold = newThreshold;
        emit RecoveryApprovalThresholdChanged(oldThreshold, newThreshold);
    }

    function __AEDRecovery_init() internal onlyInitializing {}

    modifier noActiveRecovery(uint256 tokenId) {
        require(recoveryTimestamps[tokenId] == 0, "Recovery pending");
        _;
    }

    function addGuardian(uint256 tokenId, address guardian) external noActiveRecovery(tokenId) onlyInitializing {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        require(guardian != address(0), "Invalid guardian");
        require(guardian != address(this), "Cannot add contract as guardian");
        require(!_guardians[tokenId].contains(guardian), "Guardian already exists");
        require(_guardians[tokenId].length() < MAX_GUARDIANS, "Max guardians exceeded");
        require(_guardianToTokenId[guardian] == 0, "Guardian already assigned to another token");
        _guardians[tokenId].add(guardian);
        _guardianToTokenId[guardian] = tokenId;
        emit GuardianAdded(tokenId, guardian);
    }

    function removeGuardian(uint256 tokenId, address guardian) external noActiveRecovery(tokenId) onlyInitializing {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        require(_guardians[tokenId].length() > 1, "Cannot remove last guardian");
        if (_guardians[tokenId].remove(guardian)) onlyInitializing; {
            // If guardian had approved, decrement approval count
            if (recoveryApprovals[tokenId][guardian]) {
                recoveryApprovalCounts[tokenId] -= 1;
                delete recoveryApprovals[tokenId][guardian];
            }
            emit GuardianRemoved(tokenId, guardian);
        }
    }

    function initiateRecovery(uint256 tokenId) external {
        require(_guardians[tokenId].contains(msg.sender), "Not guardian");
        require(recoveryTimestamps[tokenId] == 0, "Recovery pending");
        recoveryTimestamps[tokenId] = block.timestamp + RECOVERY_DELAY;
        emit RecoveryInitiated(tokenId, recoveryTimestamps[tokenId]);
    }

    function approveRecovery(uint256 tokenId) external {
        require(_guardians[tokenId].contains(msg.sender), "Not guardian");
        require(recoveryTimestamps[tokenId] != 0, "No recovery pending");
        require(!recoveryApprovals[tokenId][msg.sender], "Already approved");
        recoveryApprovals[tokenId][msg.sender] = true;
        recoveryApprovalCounts[tokenId] += 1;
        emit RecoveryApproved(tokenId, msg.sender);
    }

    /// @notice Finalizes the recovery process for a token if approval threshold is met.
    /// @param tokenId The unique identifier of the token to recover.
    /// @param newOwner The address to transfer ownership to.
    function completeRecovery(uint256 tokenId, address newOwner) 
        external 
        nonReentrant 
    {
        require(recoveryTimestamps[tokenId] != 0, "No recovery pending");
        require(_guardians[tokenId].contains(msg.sender), "Not guardian");
        require(
            recoveryApprovalCounts[tokenId] >= recoveryApprovalThreshold,
            "Not enough approvals"
        );
        // Prevent assigning ownership to a guardian
        require(!_guardians[tokenId].contains(newOwner), "New owner cannot be a guardian");
        // Clear all approvals for this tokenId
        address[] memory guardians = _guardians[tokenId].values();
        for (uint256 i = 0; i < guardians.length; i++) {
            recoveryApprovals[tokenId][guardians[i]] = false;
        }
        require(block.timestamp >= recoveryTimestamps[tokenId], "Delay not passed");
        require(newOwner != address(0), "Invalid owner");
        address currentOwner = ownerOf(tokenId);
        _transfer(currentOwner, newOwner, tokenId);
        delete recoveryTimestamps[tokenId];
        delete recoveryApprovalCounts[tokenId];
        emit RecoveryCompleted(tokenId, newOwner);
    }

    function cancelRecovery(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner");
        require(recoveryTimestamps[tokenId] != 0, "No recovery pending");
        // Clear all approvals for this tokenId
        address[] memory guardians = _guardians[tokenId].values();
        for (uint256 i = 0; i < guardians.length; i++) {
            recoveryApprovals[tokenId][guardians[i]] = false;
        }
        delete recoveryTimestamps[tokenId];
        delete recoveryApprovalCounts[tokenId];
        emit RecoveryCanceled(tokenId);
    }

    function getGuardians(uint256 tokenId) public view returns (address[] memory) {
        return _guardians[tokenId].values();
    }

    function setRecoveryLockDuration(uint256 duration) external onlyRole(ADMIN_ROLE) {
        recoveryLockDuration = duration;
    }

    function canCompleteRecovery(uint256 tokenId) public view returns (bool) {
        return block.timestamp >= recoveryTimestamps[tokenId] + recoveryLockDuration;
    }

    // Storage gap for future upgrades
    uint256[50] private __gap;
}