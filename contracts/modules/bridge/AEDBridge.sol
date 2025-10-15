// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../base/ModuleBase.sol";
import "../../libraries/LibBridge.sol";

contract AEDBridge is ModuleBase {
    
    event DomainBridgeRequested(uint256 indexed tokenId, uint256 indexed targetChainId);
    event DomainUnbridgeRequested(uint256 indexed tokenId);
    
    function bridgeDomain(uint256 tokenId, uint256 targetChainId) external onlyTokenOwner(tokenId) {
        LibBridge.bridgeDomain(tokenId, targetChainId);
        emit DomainBridgeRequested(tokenId, targetChainId);
    }
    
    function unbridgeDomain(uint256 tokenId) external onlyTokenOwner(tokenId) {
        LibBridge.unbridgeDomain(tokenId);
        emit DomainUnbridgeRequested(tokenId);
    }
    
    function getBridgeInfo(uint256 tokenId) external view returns (
        uint256 chainId,
        address bridgeAddress,
        uint256 bridgedAt,
        bool bridgedOut
    ) {
        BridgeInfo memory info = LibBridge.getBridgeInfo(tokenId);
        return (info.chainId, info.bridgeAddress, info.bridgedAt, info.isBridgedOut);
    }
    
    function isBridged(uint256 tokenId) external view returns (bool) {
        return LibBridge.isBridged(tokenId);
    }
    
    function configureBridge(
        uint256 chainId,
        address bridgeAddress,
        bool enabled
    ) external onlyAdmin {
        LibBridge.configureBridge(chainId, bridgeAddress, enabled);
    }
    
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AED_BRIDGE");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AED Bridge";
    }
}
