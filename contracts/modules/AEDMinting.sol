// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AEDCore.sol";

abstract contract AEDMinting is AEDCore {
    function registerDomain(
        string memory name,
        string memory tld,
        uint256 mintFee,
        bool    feeEnabled,
        uint256 duration
    ) external payable {
        require(msg.value >= renewalPrice * duration, "Insufficient payment");
        string memory full = string.concat(name, ".", tld);
        require(!registered[full], "Taken");

        uint256 id = nextTokenId++;
        _safeMint(msg.sender, id);

        domains[id] = Domain(
            name, tld, "", "", 0, mintFee, feeEnabled,
            uint64(block.timestamp + duration), false
        );
        registered[full] = true;
        emit DomainRegistered(id, full);
    }

    function mintSubdomain(uint256 rootId, string memory sub) external payable {
        require(_exists(rootId), "Root missing");
        require(ownerOf(rootId) == msg.sender, "Not root owner");
        require(domains[rootId].expiresAt > block.timestamp, "Root expired");

        Domain storage r = domains[rootId];
        string memory full = string.concat(sub, ".", r.name, ".", r.tld);
        require(!registered[full], "Taken");

        if (r.feeEnabled) {
            uint256 fee = r.mintFee * (1 + r.subdomainCount);
            require(msg.value >= fee, "Fee low");
        }

        uint256 id = nextTokenId++;
        _safeMint(msg.sender, id);

        domains[id] = Domain(sub, string.concat(r.name,".",r.tld),"","",0,0,false,r.expiresAt,true);
        r.subdomainCount++;
        registered[full] = true;
        emit SubdomainCreated(rootId, id, full);
    }

    function renewDomain(uint256 id, uint256 duration) external payable {
        require(_isApprovedOrOwner(msg.sender,id),"Not owner");
        require(msg.value >= renewalPrice * duration,"Low payment");
        domains[id].expiresAt += uint64(duration);
        emit Renewed(id, duration);
    }
}
