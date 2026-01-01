// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title LibPayment
 * @dev Handles USDC payments for all AED fees
 * 
 * All prices stored in USDC (6 decimals: 1000000 = $1.00)
 * Admin can adjust any fee amount at any time
 */
library LibPayment {
    using LibAppStorage for AppStorage;

    // USDC address on Polygon (update for testnet/mainnet)
    address constant USDC_ADDRESS = 0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582; // Polygon Amoy testnet USDC

    event PaymentReceived(address indexed payer, uint256 amount, string feeType);
    event FeeCollected(address indexed collector, uint256 amount);

    error InsufficientPayment(uint256 required, uint256 provided);
    error PaymentFailed();

    /**
     * @dev Collect USDC payment from user
     * @param amount USDC amount (6 decimals: 1000000 = $1.00)
     * @param feeType Description of what fee is for
     */
    function collectPayment(uint256 amount, string memory feeType) internal {
        if (amount == 0) return;

        AppStorage storage s = LibAppStorage.appStorage();
        IERC20 usdc = IERC20(USDC_ADDRESS);

        // Check user has enough USDC and approved the contract
        uint256 allowance = usdc.allowance(msg.sender, address(this));
        if (allowance < amount) {
            revert InsufficientPayment(amount, allowance);
        }

        // Transfer USDC from user to fee collector
        bool success = usdc.transferFrom(msg.sender, s.feeCollector, amount);
        if (!success) {
            revert PaymentFailed();
        }

        s.totalRevenue += amount;

        emit PaymentReceived(msg.sender, amount, feeType);
        emit FeeCollected(s.feeCollector, amount);
    }

    /**
     * @dev Get USDC token interface
     */
    function getUSDC() internal pure returns (IERC20) {
        return IERC20(USDC_ADDRESS);
    }

    /**
     * @dev Check if user has approved enough USDC
     */
    function checkAllowance(address user, uint256 amount) internal view returns (bool) {
        return IERC20(USDC_ADDRESS).allowance(user, address(this)) >= amount;
    }

    /**
     * @dev Get user's USDC balance
     */
    function getBalance(address user) internal view returns (uint256) {
        return IERC20(USDC_ADDRESS).balanceOf(user);
    }
}
