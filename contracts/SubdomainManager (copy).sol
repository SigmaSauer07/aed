// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./AEDRenderer.sol";
import "./AEDPricing.sol";

contract SubdomainManager {
    IERC721 public domainRegistry;
    AEDRenderer public renderer;
    AEDPricing public pricing;
    
    // Subdomain to parent mapping
    mapping(uint256 => uint256) public subdomainToParent;
    mapping(uint256 => uint256[]) public parentToSubdomains;
    
    event SubdomainCreated(uint256 indexed parentId, uint256 subdomainId, string label);
    
    constructor() {
        domainRegistry = IERC721(msg.sender);
        renderer = AEDRenderer(address(0)); // Set by registry
        pricing = AEDPricing(address(0)); // Set by registry
    }
    
    function createSubdomain(
        uint256 parentId,
        string calldata label,
        bool darkMode
    ) external payable {
        require(domainRegistry.ownerOf(parentId) == msg.sender, "Not owner");
        
        // Calculate price
        string memory parentName = AEDRegistry(address(domainRegistry)).tokenIdToName(parentId);
        (, string memory tld) = _splitDomain(parentName);
        uint256 price = pricing.getSubdomainPrice(label, tld);
        require(msg.value >= price, "Insufficient payment");
        
        // Create subdomain ID
        string memory fullName = string(abi.encodePacked(label, ".", parentName));
        uint256 subdomainId = uint256(keccak256(bytes(fullName)));
        
        // Mint subdomain
        domainRegistry.safeMint(msg.sender, subdomainId);
        
        // Set metadata
        renderer.initializeMetadata(subdomainId, fullName, darkMode);
        AEDRenderer(address(renderer)).setSubdomain(subdomainId, true);
        
        // Link to parent
        subdomainToParent[subdomainId] = parentId;
        parentToSubdomains[parentId].push(subdomainId);
        
        emit SubdomainCreated(parentId, subdomainId, label);
    }
    
    function _splitDomain(string memory domain) internal pure returns (string memory, string memory) {
        bytes memory b = bytes(domain);
        for(uint i = 0; i < b.length; i++) {
            if(b[i] == ".") {
                return (
                    string(b[0:i]), 
                    string(b[i+1:b.length])
                );
            }
        }
        return (domain, "");
    }
}