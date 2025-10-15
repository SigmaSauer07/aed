// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../contracts/core/AEDCore.sol";

contract AEDCoreTest is AEDCore {
    function initialize(string memory name_, string memory symbol_, address admin) public initializer {
        __AEDCore_init(name_, symbol_, admin);
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
        s().nextTokenId = tokenId + 1;
    }

    function setTokenURI(uint256 tokenId, string memory uri) public {
        s().tokenURIs[tokenId] = uri;
    }

    function setDomain(uint256 tokenId, string memory domainName, string memory tld) public {
        s().domains[tokenId].name = domainName;
        s().domains[tokenId].tld = tld;
        s().domains[tokenId].owner = ownerOf(tokenId);
    }
}