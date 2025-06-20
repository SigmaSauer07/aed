// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AEDCore.sol";

abstract contract AEDReverse is AEDCore {
    mapping(address => uint256) internal reverseRecord;

    function setReverseRecord(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        reverseRecord[msg.sender] = tokenId;
    }

    function clearReverseRecord() external {
        delete reverseRecord[msg.sender];
    }

    function getReverseDomain(address user) external view returns (string memory) {
        uint256 tokenId = reverseRecord[user];
        if (!_exists(tokenId)) return "";
        Domain memory d = domains[tokenId];
        return string(abi.encodePacked(d.name, ".", d.tld));
    }
}
