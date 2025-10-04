// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./external/oz/proxy/ERC1967/ERC1967Proxy.sol";

/// @title AED Proxy Contract
/// @dev Simple proxy that delegates to AEDImplementation
contract AED is ERC1967Proxy {
    constructor(
        address implementation,
        bytes memory data
    ) ERC1967Proxy(implementation, data) {}
}
