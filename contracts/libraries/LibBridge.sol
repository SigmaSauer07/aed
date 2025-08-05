// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

library LibBridge {
    using LibAppStorage for AppStorage;
    
    event DomainBridged(uint256 indexed tokenId, uint256 destChainId, bytes32 bridgeHash);
    event DomainClaimed(uint256 indexed tokenId, address indexed claimer, uint256 sourceChainId);
    event ChainSupportUpdated(uint256 indexed chainId, bool supported);
    
    function bridgeDomain(uint256 tokenId, string calldata destination) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        require(!s.bridgeData[tokenId].isBridged, "Already bridged");
        
        uint256 destChainId = _parseChainId(destination);
        require(_isSupportedChain(destChainId), "Unsupported chain");
        
        address tokenOwner = s.owners[tokenId];
        bytes32 bridgeHash = keccak256(abi.encode(
            tokenId,
            destChainId,
            block.timestamp,
            tokenOwner,
            block.chainid
        ));
        
        s.bridgeData[tokenId] = BridgeReceipt({
            destChainId: destChainId,
            bridgeHash: bridgeHash,
            timestamp: block.timestamp,
            isBridged: true
        });
        
        emit DomainBridged(tokenId, destChainId, bridgeHash);
    }
    
    function claimBridgedDomain(
        uint256 tokenId,
        bytes32 bridgeHash,
        bytes calldata signature
    ) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] == address(0), "Token already exists");
        
        // Verify signature (simplified - in production use proper signature verification)
        bytes32 messageHash = keccak256(abi.encode(tokenId, bridgeHash, block.chainid));
        address signer = _recoverSigner(messageHash, signature);
        
        // Create the domain on this chain
        s.owners[tokenId] = signer;
        s.balances[signer]++;
        
        // Initialize basic domain data
        string memory domain = string(abi.encodePacked("bridged", _toString(tokenId), ".aed"));
        s.tokenIdToDomain[tokenId] = domain;
        s.domainToTokenId[domain] = tokenId;
        s.domainExists[domain] = true;
        s.userDomains[signer].push(domain);
        
        s.domains[tokenId] = Domain({
            name: string(abi.encodePacked("bridged", _toString(tokenId))),
            tld: "aed",
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: false,
            owner: signer
        });
        
        emit DomainClaimed(tokenId, signer, 0); // Source chain ID would be in signature
    }
    
    function getBridgeInfo(uint256 tokenId) internal view returns (
        uint256 destChainId,
        bytes32 bridgeHash,
        uint256 timestamp,
        bool isBridged
    ) {
        AppStorage storage s = LibAppStorage.appStorage();
        BridgeReceipt memory receipt = s.bridgeData[tokenId];
        return (receipt.destChainId, receipt.bridgeHash, receipt.timestamp, receipt.isBridged);
    }
    
    function isBridged(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.appStorage().bridgeData[tokenId].isBridged;
    }
    
    function setSupportedChain(uint256 chainId, bool supported) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        bytes32 chainSlot = keccak256(abi.encode("supportedChain", chainId));
        s.futureUint256[uint256(chainSlot)] = supported ? 1 : 0;
        emit ChainSupportUpdated(chainId, supported);
    }
    
    function isSupportedChain(uint256 chainId) internal view returns (bool) {
        return _isSupportedChain(chainId);
    }
    
    function _parseChainId(string calldata destination) internal pure returns (uint256) {
        // Simple parsing - in production, use proper chain name to ID mapping
        if (keccak256(bytes(destination)) == keccak256("ethereum")) return 1;
        if (keccak256(bytes(destination)) == keccak256("polygon")) return 137;
        if (keccak256(bytes(destination)) == keccak256("arbitrum")) return 42161;
        if (keccak256(bytes(destination)) == keccak256("optimism")) return 10;
        revert("Unknown destination");
    }
    
    function _isSupportedChain(uint256 chainId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        bytes32 chainSlot = keccak256(abi.encode("supportedChain", chainId));
        return s.futureUint256[uint256(chainSlot)] == 1;
    }
    
    function _recoverSigner(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        return ecrecover(messageHash, v, r, s);
    }
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
}
