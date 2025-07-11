// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../core/CoreState.sol";

/**
 * @title AEDReverse
 * @dev Module for reverse resolution (address -> domain). Users can set one of their domains as the reverse record for their address.
 */
abstract contract AEDReverse is Initializable, CoreState {
    event ReverseRecordSet(address indexed wallet, uint256 indexed tokenId);
    event ReverseRecordCleared(address indexed wallet);

    mapping(address => uint256) public reverseRecord;  // maps user wallet to a tokenId they set as reverse

    function __AEDReverse_init() internal onlyInitializing {
        // no state init required
    }

    function setReverseRecord(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        require(!domains[tokenId].isSubdomain, "Subdomains cannot set reverse");
        reverseRecord[msg.sender] = tokenId;
        emit ReverseRecordSet(msg.sender, tokenId);
    }

    function clearReverseRecord() external {
        require(reverseRecord[msg.sender] != 0, "No reverse record");
        delete reverseRecord[msg.sender];
        emit ReverseRecordCleared(msg.sender);
    }

    function getReverseDomain(address user) external view returns (string memory) {
        uint256 tokenId = reverseRecord[user];
        if (!_exists(tokenId)) {
            return "";
        }
        Domain memory d = domains[tokenId];
        return string(abi.encodePacked(d.name, ".", d.tld));
    }

    uint256[50] private __gap;

    function initializeModule_Reverse() public virtual onlyInitializing {
        // Initialization logic for Reverse module (optional)
    }

}
