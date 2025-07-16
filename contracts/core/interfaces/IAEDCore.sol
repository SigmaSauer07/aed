// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IAEDCore
 * @dev External view-only interface for AED Core functionality
 */
interface IAEDCore {
    // View functions
    function getDomainFeatures(uint256 tokenId) external view returns (uint256);
    function getNextTokenId() external view returns (uint256);
    function getFeeCollector() external view returns (address);
    function domains(uint256 tokenId) external view returns (
        string memory name,
        string memory tld,
        string memory profileURI,
        string memory imageURI,
        uint256 subdomainCount,
        uint256 mintFee,
        uint64 expiresAt,
        bool feeEnabled,
        bool isSubdomain,
        address owner
    );
    
    // Module supportion
    function supportsModule(bytes32 moduleId) external view returns (bool);
    function moduleId() external pure returns (bytes32);
    function moduleVersion() external pure returns (uint256);
    function dependencies() external pure returns (bytes32[] memory);
    function initialize(bytes calldata data) external;
    function isEnabled() external view returns (bool);
    function enable(bool enabled) external;
    
    // ERC721 standard
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // Access control
    function hasRole(bytes32 role, address account) external view returns (bool);
    
    // Pause state
    function paused() external view returns (bool);
}