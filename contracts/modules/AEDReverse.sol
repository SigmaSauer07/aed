// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/CoreState.sol";

abstract contract AEDReverse is CoreState {
    event ReverseRecordSet(address indexed wallet, uint256 indexed tokenId);
    event ReverseRecordCleared(address indexed wallet);

    mapping(address => uint256) public reverseRecord;

    function __AEDReverse_init() internal {}

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
        if (!_exists(tokenId)) return "";
        Domain memory d = domains[tokenId];
        return string(abi.encodePacked(d.name, ".", d.tld));
    }

    uint256[50] private __gap;
}