// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDBridge {
    // Events
    event DomainBridgeRequested(uint256 indexed tokenId, uint256 indexed targetChainId);
    event DomainUnbridgeRequested(uint256 indexed tokenId);
    
    // Functions
    function bridgeDomain(uint256 tokenId, string calldata destination) external;
    function claimBridgedDomain(uint256 tokenId, bytes32 bridgeHash, bytes calldata signature) external;
    function getBridgeInfo(uint256 tokenId) external view returns (
        uint256 destChainId,
        bytes32 bridgeHash,
        uint256 timestamp,
        bool isBridged
    );
    function isBridged(uint256 tokenId) external view returns (bool);
    function isSupportedChain(uint256 chainId) external view returns (bool);
}
