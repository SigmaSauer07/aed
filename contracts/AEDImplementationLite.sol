// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./AEDImplementation.sol";

/**
 * @dev Lightweight alias of the primary AEDImplementation.  Maintained for
 * backwards compatibility with deployment scripts and tests that expect a
 * "Lite" implementation while sharing the same audited logic.
 */
contract AEDImplementationLite is AEDImplementation {}
