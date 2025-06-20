// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AEDCore.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

abstract contract AEDMetadata is AEDCore, IERC2981 {
    function setProfileURI(uint256 id,string memory uri) external {
        require(_isApprovedOrOwner(msg.sender,id),"Not owner");
        domains[id].profileURI = uri;
    }
    function setRoyaltyBps(uint256 bps) external onlyRole(ADMIN_ROLE){
        require(bps<=1000,"0-1000");
        royaltyBps = bps;
    }
    function tokenURI(uint256 id) public view virtual override returns(string memory) {
        require(_exists(id),"Missing");
        Domain memory d = domains[id];
        string memory nm = string.concat(d.name,".",d.tld);
        string memory img = bytes(d.imageURI).length>0 ? d.imageURI : _svg(nm,d.isSubdomain);
        string memory json = Base64.encode(bytes(string.concat(
            '{"name":"',nm,'","description":"Alsania Enhanced Domain","image":"',img,'"}'
        )));
        return string.concat("data:application/json;base64,", json);
    }
    function _svg(string memory nm,bool sub) internal pure returns(string memory){
        string memory bg = sub ? SUB_BG : DOMAIN_BG;
        string memory svg=Base64.encode(bytes(string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400">',
              "<defs>",
                "<style>@import url(\'https://fonts.googleapis.com/css2?family=Permanent+Marker\');</style>",
                '<filter id="glow" x="-50%" y="-50%" width="200%" height="200%">',
                  '<feGaussianBlur stdDeviation="2.5" result="blur"/>',
                  '<feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>',
                "</filter>",
              "</defs>",
              '<image href="', bg, '" width="400" height="400"/>',
              '<text x="50%" y="92%" text-anchor="middle" dominant-baseline="middle" ',
                'font-family="Permanent Marker" font-size="24" fill="', NEON_GREEN, '" filter="url(#glow)">',
                nm,"</text></svg>"
        )));
        return string.concat("data:image/svg+xml;base64,", svg);
    }
    function royaltyInfo(uint256 id,uint256 sale) external view override returns(address,uint256){
        require(_exists(id),"Missing");
        return (ownerOf(id), (sale*royaltyBps)/10000);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AEDCore, IERC165)
        returns (bool)
    {
        // Advertise royalty interface plus whatever parents report
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
