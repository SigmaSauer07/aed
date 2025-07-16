// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../modules/base/ModuleBase.sol";
import "../../interfaces/modules/IAEDRecovery.sol";

/**
 * @title AEDRecovery
 * @dev Module for account recovery via guardians.
 */
abstract contract AEDRecovery is Initializable, ModuleBase, IAEDRecovery {
    function s() internal pure returns (AppStorage.Layout storage) {
        return AppStorage.layout();
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(s().domains[tokenId].owner == msg.sender, "Not token owner");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(s().domains[tokenId].owner != address(0), "Token does not exist");
        _;
    }

    modifier hasFeature(uint256 tokenId, uint256 feature) {
        require(s().domainFeatures[tokenId] & feature != 0, "Feature not enabled");
        _;
    }

    function _setFeature(uint256 tokenId, uint256 feature) internal {
        s().domainFeatures[tokenId] |= feature;
        emit FeatureEnabled(tokenId, feature);
    }

    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return IAEDCore(address(this)).hasRole(role, account);
    }

    function getModuleVersion() external pure virtual override returns (uint256) {
        return 1;
    }

    event GuardianAdded(uint256 indexed tokenId, address indexed guardian);
    event GuardianRemoved(uint256 indexed tokenId, address indexed guardian);
    event RecoveryInitiated(uint256 indexed tokenId, uint256 unlockTime);
    event RecoveryCompleted(uint256 indexed tokenId, address indexed newOwner);
    event RecoveryCanceled(uint256 indexed tokenId);
    event RecoveryApproved(uint256 indexed tokenId, address indexed guardian);
    event RecoveryApprovalThresholdChanged(uint256 oldThreshold, uint256 newThreshold);

    uint256 public MAX_GUARDIANS;
    uint256 public RECOVERY_DELAY = 3 days;
    uint256 public recoveryApprovalThreshold;
    uint256 public recoveryLockDuration;

    mapping(uint256 => address[]) public _guardians;
    mapping(uint256 => uint256) public recoveryTimestamps;
    mapping(uint256 => mapping(address => bool)) public recoveryApprovals;
    mapping(uint256 => uint256) public recoveryApprovalCounts;
    mapping(address => uint256) private _guardianToTokenId;

    function __AEDRecovery_init(uint256 maxGuardians, uint256 approvalThreshold) internal onlyInitializing {
        MAX_GUARDIANS = maxGuardians;
        recoveryApprovalThreshold = approvalThreshold;
        __ReentrancyGuard_init();
    }

    modifier noActiveRecovery(uint256 tokenId) {
        require(recoveryTimestamps[tokenId] == 0, "Recovery pending");
        _;
    }

    function completeRecovery(uint256 tokenId, address newOwner) external payable nonReentrant {
        require(_guardians[tokenId].length > 0, "No guardians set");
        require(recoveryTimestamps[tokenId] != 0, "No recovery pending");
        require(recoveryApprovalCounts[tokenId] >= recoveryApprovalThreshold, "Not enough approvals");
        require(!_guardians[tokenId].contains(newOwner), "New owner cannot be a guardian");
        require(block.timestamp >= recoveryTimestamps[tokenId], "Delay not passed");
        require(newOwner != address(0), "Invalid owner");

        address currentOwner = ownerOf(tokenId);
        _transferDomain(currentOwner, newOwner, tokenId);

        delete recoveryTimestamps[tokenId];
        delete recoveryApprovalCounts[tokenId];

        address[] memory guardians = _guardians[tokenId];
        for (uint256 i = 0; i < guardians.length; i++) {
            delete recoveryApprovals[tokenId][guardians[i]];
        }

        emit RecoveryCompleted(tokenId, newOwner);
    }

    uint256[50] private __gap;
}
