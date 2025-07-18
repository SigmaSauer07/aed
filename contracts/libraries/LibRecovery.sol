// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../libraries/LibAppStorage.sol";
import "../core/AEDConstants.sol";

struct RecoveryRequest {
    address newOwner;
    uint256 confirmations;
    uint256 requiredConfirmations;
    uint256 deadline;
    bool isActive;
    mapping(address => bool) hasConfirmed;
}

library LibRecovery {
    using LibAppStorage for AppStorage;
    
    // Use future storage slots for recovery data
    bytes32 constant RECOVERY_STORAGE_SLOT = keccak256("aed.recovery.storage");
    
    event GuardianAdded(uint256 indexed tokenId, address indexed guardian);
    event GuardianRemoved(uint256 indexed tokenId, address indexed guardian);
    event RecoveryInitiated(uint256 indexed tokenId, address indexed newOwner, uint256 deadline);
    event RecoveryConfirmed(uint256 indexed tokenId, address indexed guardian);
    event RecoveryCancelled(uint256 indexed tokenId);
    event RecoveryExecuted(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);
    
    function addGuardian(uint256 tokenId, address guardian) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        require(guardian != address(0), "Invalid guardian");
        require(guardian != s.owners[tokenId], "Owner cannot be guardian");
        
        // Use future storage for guardians list
        bytes32 guardiansSlot = keccak256(abi.encode(tokenId, "guardians"));
        uint256 guardianCount = s.futureUint256[uint256(guardiansSlot)];
        
        // Check if already a guardian
        for (uint256 i = 0; i < guardianCount; i++) {
            bytes32 guardianSlot = keccak256(abi.encode(tokenId, "guardian", i));
            if (s.futureAddressUint256[guardian] == uint256(uint160(guardian))) {
                revert("Already a guardian");
            }
        }
        
        // Add new guardian
        bytes32 newGuardianSlot = keccak256(abi.encode(tokenId, "guardian", guardianCount));
        s.futureAddressUint256[guardian] = uint256(uint160(guardian));
        s.futureUint256[uint256(guardiansSlot)] = guardianCount + 1;
        
        emit GuardianAdded(tokenId, guardian);
    }
    
    function removeGuardian(uint256 tokenId, address guardian) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        
        bytes32 guardiansSlot = keccak256(abi.encode(tokenId, "guardians"));
        uint256 guardianCount = s.futureUint256[uint256(guardiansSlot)];
        
        bool found = false;
        for (uint256 i = 0; i < guardianCount; i++) {
            if (s.futureAddressUint256[guardian] == uint256(uint160(guardian))) {
                // Remove guardian by setting to 0
                s.futureAddressUint256[guardian] = 0;
                found = true;
                break;
            }
        }
        
        require(found, "Not a guardian");
        emit GuardianRemoved(tokenId, guardian);
    }
    
    function initiateRecovery(uint256 tokenId, address newOwner) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        require(newOwner != address(0), "Invalid new owner");
        require(isGuardian(tokenId, msg.sender), "Not a guardian");
        
        bytes32 recoverySlot = keccak256(abi.encode(tokenId, "recovery"));
        require(s.futureUint256[uint256(recoverySlot)] == 0, "Recovery already active");
        
        uint256 guardianCount = getGuardianCount(tokenId);
        require(guardianCount > 0, "No guardians");
        
        uint256 requiredConfirmations = (guardianCount * 60) / 100; // 60% threshold
        if (requiredConfirmations == 0) requiredConfirmations = 1;
        
        // Store recovery data in future storage
        bytes32 newOwnerSlot = keccak256(abi.encode(tokenId, "recovery", "newOwner"));
        bytes32 confirmationsSlot = keccak256(abi.encode(tokenId, "recovery", "confirmations"));
        bytes32 requiredSlot = keccak256(abi.encode(tokenId, "recovery", "required"));
        bytes32 deadlineSlot = keccak256(abi.encode(tokenId, "recovery", "deadline"));
        bytes32 activeSlot = keccak256(abi.encode(tokenId, "recovery", "active"));
        
        s.futureAddressUint256[newOwner] = uint256(uint160(newOwner));
        s.futureUint256[uint256(confirmationsSlot)] = 1; // Initiator's confirmation
        s.futureUint256[uint256(requiredSlot)] = requiredConfirmations;
        s.futureUint256[uint256(deadlineSlot)] = block.timestamp + 7 days;
        s.futureUint256[uint256(activeSlot)] = 1;
        
        // Mark initiator as confirmed
        bytes32 confirmedSlot = keccak256(abi.encode(tokenId, "recovery", "confirmed", msg.sender));
        s.futureUint256[uint256(confirmedSlot)] = 1;
        
        emit RecoveryInitiated(tokenId, newOwner, block.timestamp + 7 days);
        emit RecoveryConfirmed(tokenId, msg.sender);
    }
    
    function confirmRecovery(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(isGuardian(tokenId, msg.sender), "Not a guardian");
        
        bytes32 activeSlot = keccak256(abi.encode(tokenId, "recovery", "active"));
        require(s.futureUint256[uint256(activeSlot)] == 1, "No active recovery");
        
        bytes32 deadlineSlot = keccak256(abi.encode(tokenId, "recovery", "deadline"));
        require(block.timestamp <= s.futureUint256[uint256(deadlineSlot)], "Recovery expired");
        
        bytes32 confirmedSlot = keccak256(abi.encode(tokenId, "recovery", "confirmed", msg.sender));
        require(s.futureUint256[uint256(confirmedSlot)] == 0, "Already confirmed");
        
        // Add confirmation
        s.futureUint256[uint256(confirmedSlot)] = 1;
        
        bytes32 confirmationsSlot = keccak256(abi.encode(tokenId, "recovery", "confirmations"));
        s.futureUint256[uint256(confirmationsSlot)]++;
        
        emit RecoveryConfirmed(tokenId, msg.sender);
    }
    
    function cancelRecovery(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        
        _clearRecovery(tokenId);
        emit RecoveryCancelled(tokenId);
    }
    
    function executeRecovery(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        bytes32 activeSlot = keccak256(abi.encode(tokenId, "recovery", "active"));
        require(s.futureUint256[uint256(activeSlot)] == 1, "No active recovery");
        
        bytes32 deadlineSlot = keccak256(abi.encode(tokenId, "recovery", "deadline"));
        require(block.timestamp <= s.futureUint256[uint256(deadlineSlot)], "Recovery expired");
        
        bytes32 confirmationsSlot = keccak256(abi.encode(tokenId, "recovery", "confirmations"));
        bytes32 requiredSlot = keccak256(abi.encode(tokenId, "recovery", "required"));
        
        uint256 confirmations = s.futureUint256[uint256(confirmationsSlot)];
        uint256 required = s.futureUint256[uint256(requiredSlot)];
        
        require(confirmations >= required, "Insufficient confirmations");
        
        // Execute transfer
        address oldOwner = s.owners[tokenId];
        address newOwner = address(uint160(s.futureAddressUint256[address(0)])); // Get from storage
        
        s.owners[tokenId] = newOwner;
        s.balances[oldOwner]--;
        s.balances[newOwner]++;
        s.domains[tokenId].owner = newOwner;
        
        _clearRecovery(tokenId);
        emit RecoveryExecuted(tokenId, oldOwner, newOwner);
    }
    
    function getGuardians(uint256 tokenId) internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        bytes32 guardiansSlot = keccak256(abi.encode(tokenId, "guardians"));
        uint256 guardianCount = s.futureUint256[uint256(guardiansSlot)];
        
        address[] memory guardians = new address[](guardianCount);
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < guardianCount; i++) {
            bytes32 guardianSlot = keccak256(abi.encode(tokenId, "guardian", i));
            address guardian = address(uint160(s.futureUint256[uint256(guardianSlot)]));
            if (guardian != address(0)) {
                guardians[activeCount] = guardian;
                activeCount++;
            }
        }
        
        // Resize array to active count
        assembly {
            mstore(guardians, activeCount)
        }
        
        return guardians;
    }
    
    function getRecoveryInfo(uint256 tokenId) internal view returns (
        address newOwner,
        uint256 confirmations,
        uint256 requiredConfirmations,
        uint256 deadline,
        bool isActive
    ) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        bytes32 activeSlot = keccak256(abi.encode(tokenId, "recovery", "active"));
        isActive = s.futureUint256[uint256(activeSlot)] == 1;
        
        if (isActive) {
            bytes32 newOwnerSlot = keccak256(abi.encode(tokenId, "recovery", "newOwner"));
            bytes32 confirmationsSlot = keccak256(abi.encode(tokenId, "recovery", "confirmations"));
            bytes32 requiredSlot = keccak256(abi.encode(tokenId, "recovery", "required"));
            bytes32 deadlineSlot = keccak256(abi.encode(tokenId, "recovery", "deadline"));
            
            newOwner = address(uint160(s.futureUint256[uint256(newOwnerSlot)]));
            confirmations = s.futureUint256[uint256(confirmationsSlot)];
            requiredConfirmations = s.futureUint256[uint256(requiredSlot)];
            deadline = s.futureUint256[uint256(deadlineSlot)];
        }
    }
    
    function isGuardian(uint256 tokenId, address account) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.futureAddressUint256[account] == uint256(uint160(account));
    }
    
    function getGuardianCount(uint256 tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        bytes32 guardiansSlot = keccak256(abi.encode(tokenId, "guardians"));
        return s.futureUint256[uint256(guardiansSlot)];
    }
    
    function _clearRecovery(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        bytes32 activeSlot = keccak256(abi.encode(tokenId, "recovery", "active"));
        bytes32 newOwnerSlot = keccak256(abi.encode(tokenId, "recovery", "newOwner"));
        bytes32 confirmationsSlot = keccak256(abi.encode(tokenId, "recovery", "confirmations"));
        bytes32 requiredSlot = keccak256(abi.encode(tokenId, "recovery", "required"));
        bytes32 deadlineSlot = keccak256(abi.encode(tokenId, "recovery", "deadline"));
        
        s.futureUint256[uint256(activeSlot)] = 0;
        s.futureUint256[uint256(newOwnerSlot)] = 0;
        s.futureUint256[uint256(confirmationsSlot)] = 0;
        s.futureUint256[uint256(requiredSlot)] = 0;
        s.futureUint256[uint256(deadlineSlot)] = 0;
    }
}