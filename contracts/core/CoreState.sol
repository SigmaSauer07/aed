// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract CoreState {
    // Optimized struct packing to save gas by grouping similar types
    struct Domain {
        // Group strings together (each takes a full slot)
        string name;
        string tld;
        string profileURI;
        string imageURI;
        
        // Group uint256 values (each takes a full slot)
        uint256 subdomainCount;
        uint256 mintFee;
        
        // Pack smaller values together in a single slot
        uint64 expiresAt;
        bool feeEnabled;
        bool isSubdomain;
        address owner; // 20 bytes
    }

    // Storage variables
    mapping(uint256 => Domain) internal domains;
    mapping(bytes32 => bool) internal registered;
    uint256 internal nextTokenId;
    uint256 internal royaltyBps;
    address internal feeCollector;
    mapping(uint256 => uint256) internal domainFeatures;  // Feature flags using bitmap for gas efficiency

    // Abstract functions to be implemented by core logic
    function _exists(uint256 tokenId) internal view virtual returns (bool);
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool);
    function _isApproved(address spender, uint256 tokenId) internal view virtual returns (bool);
    function _isApprovedForAll(address owner, address operator) internal view virtual returns (bool);
    function hasRole(bytes32 role, address account) public view virtual returns (bool);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function paused() public view virtual returns (bool);

    uint256[49] private __gap;  // Storage gap for upgradeable contracts
}