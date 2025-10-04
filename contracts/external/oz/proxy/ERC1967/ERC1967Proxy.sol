// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1967UpgradeUpgradeable} from "./ERC1967UpgradeUpgradeable.sol";

contract ERC1967Proxy is ERC1967UpgradeUpgradeable {
    constructor(address implementation, bytes memory data) {
        _setAdmin(msg.sender);
        _upgradeTo(implementation);
        if (data.length > 0) {
            (bool success, bytes memory returndata) = implementation.delegatecall(data);
            require(success, string(returndata));
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        address impl = _getImplementation();
        require(impl != address(0), "Proxy: impl not set");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
