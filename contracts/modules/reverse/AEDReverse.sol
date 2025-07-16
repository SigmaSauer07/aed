// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../modules/base/ModuleBase.sol";
import "../../interfaces/modules/IAEDReverse.sol";
/**
 * @title AEDReverse
 * @dev Module for reverse resolution (address -> domain). Users can set one of their domains as the reverse record for their address.
 */
abstract contract AEDReverse is Initializable, ModuleBase, IAEDReverse {
    event ReverseRecordSet(address indexed wallet, uint256 indexed tokenId);
    event ReverseRecordCleared(address indexed wallet);

    // Internal helpers for stateless module pattern
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.getStorage();
        address owner = s.domains[tokenId].owner;
        return (spender == owner); // Expand as needed for approvals
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.getStorage();
        return s.domains[tokenId].owner != address(0);
    }

    // mapping(address => uint256) public reverseRecord;  // removed, use unified storage

    function __AEDReverse_init() internal onlyInitializing {
        // no state init required
    }

    function setReverseRecord(uint256 tokenId) external {
        AppStorage storage s = LibAppStorage.getStorage();
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        require(!s.domains[tokenId].isSubdomain, "Subdomains cannot set reverse");
        string memory fullDomain = string(abi.encodePacked(s.domains[tokenId].name, ".", s.domains[tokenId].tld));
        s.reverseRecords[msg.sender] = fullDomain;
        emit ReverseRecordSet(msg.sender, tokenId);
    }

    function clearReverseRecord() external {
        AppStorage storage s = LibAppStorage.getStorage();
        require(bytes(s.reverseRecords[msg.sender]).length != 0, "No reverse record");
        delete s.reverseRecords[msg.sender];
        emit ReverseRecordCleared(msg.sender);
    }

    function getReverseDomain(address user) external view returns (string memory) {
        AppStorage storage s = LibAppStorage.getStorage();
        return s.reverseRecords[user];
    }

    uint256[50] private __gap;

    function initializeModule_Reverse() public virtual onlyInitializing {
        // Initialization logic for Reverse module (optional)
    }

}
