// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "../../proxy/utils/Initializable.sol";
import {IERC165} from "./IERC165.sol";

abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
