// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibBridge.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDBridge.sol";

abstract contract AEDBridge is ModuleBase, IAEDBridge {
    using LibBridge for AppStorage;
    
    function bridgeDomain(uint256 tokenId, string calldata destination) external override onlyTokenOwner(tokenId) {
        LibBridge.bridgeDomain(tokenId, destination);
    }
    
    function claimBridgedDomain(
        uint256 tokenId,
        bytes32 bridgeHash,
        bytes calldata signature
    ) external override {
        LibBridge.claimBridgedDomain(tokenId, bridgeHash, signature);
    }
    
    function getBridgeInfo(uint256 tokenId) external view override returns (
        uint256 destChainId,
        bytes32 bridgeHash,
        uint256 timestamp,
        bool isBridged
    ) {
        return LibBridge.getBridgeInfo(tokenId);
    }
    
    function isBridged(uint256 tokenId) external view override returns (bool) {
        return LibBridge.isBridged(tokenId);
    }
    
    function setSupportedChain(uint256 chainId, bool supported) external onlyAdmin {
        LibBridge.setSupportedChain(chainId, supported);
    }
    
    function isSupportedChain(uint256 chainId) external view override returns (bool) {
        return LibBridge.isSupportedChain(chainId);
    }
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDBridge");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDBridge";
    }
}
