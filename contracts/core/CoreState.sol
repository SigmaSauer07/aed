// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract CoreState {
    struct Domain {
        string name;
        string tld;
        string profileURI;
        string imageURI;
        uint256 subdomainCount;
        uint256 mintFee;
        bool feeEnabled;
        uint64 expiresAt;
        bool isSubdomain;
        address owner;
    }

    mapping(uint256 => Domain) internal domains;
    mapping(bytes32 => bool) internal registered;
    uint256 internal nextTokenId;
    uint256 internal royaltyBps;
    address internal feeCollector;

    // Abstract function declarations for core access logic
    function _exists(uint256 tokenId) internal view virtual returns (bool);
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool);
    function _isApproved(address spender, uint256 tokenId) internal view virtual returns (bool);
    function _isApprovedForAll(address owner, address operator) internal view virtual returns (bool);
    function hasRole(bytes32 role, address account) public view virtual returns (bool);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function paused() public view virtual returns (bool);

    uint256[50] private __gap;
}
