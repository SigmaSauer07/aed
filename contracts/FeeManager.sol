// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title FeeManager - Handles fee collection, withdrawal, and revenue sharing
/// @author Your Team
/// @notice This module manages fee recipient and event emission
contract FeeManager {
    /// @notice The address that receives protocol fees
    address public feeRecipient;

    /// @notice Emitted when the fee recipient is set
    event FeeRecipientSet(address indexed recipient);

    /// @notice Emitted when fees are withdrawn
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    /// @notice Sets the fee recipient (admin only)
    /// @param recipient The new fee recipient address
    function setFeeRecipient(address recipient) external virtual {
        require(recipient != address(0), "Invalid address");
        feeRecipient = recipient;
        emit FeeRecipientSet(recipient);
    }

    /// @notice Withdraws all contract balance to the fee recipient
    function withdrawFees() external virtual {
        require(feeRecipient != address(0), "Fee recipient not set");
        uint256 amount = address(this).balance;
        require(amount > 0, "No fees to withdraw");
        payable(feeRecipient).transfer(amount);
        emit FeesWithdrawn(feeRecipient, amount);
    }
}