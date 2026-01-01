// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "./LibSVG.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibMetadata {
    using LibAppStorage for AppStorage;
    using Strings for uint256;

    event ProfileURIUpdated(uint256 indexed tokenId, string uri);
    event ImageURIUpdated(uint256 indexed tokenId, string uri);

    function setProfileURI(uint256 tokenId, string calldata uri) internal {
        require(LibAppStorage.tokenExists(tokenId), "Token does not exist");
        AppStorage storage s = LibAppStorage.appStorage();

        s.profileURIs[tokenId] = uri;
        s.domains[tokenId].profileURI = uri;

        emit ProfileURIUpdated(tokenId, uri);
    }

    function setImageURI(uint256 tokenId, string calldata uri) internal {
        require(LibAppStorage.tokenExists(tokenId), "Token does not exist");
        AppStorage storage s = LibAppStorage.appStorage();

        s.imageURIs[tokenId] = uri;
        s.domains[tokenId].imageURI = uri;

        emit ImageURIUpdated(tokenId, uri);
    }

    function getProfileURI(uint256 tokenId) internal view returns (string memory) {
        return LibAppStorage.appStorage().profileURIs[tokenId];
    }

    function getImageURI(uint256 tokenId) internal view returns (string memory) {
        return LibAppStorage.appStorage().imageURIs[tokenId];
    }

    function tokenURI(uint256 tokenId) internal view returns (string memory) {
        require(LibAppStorage.tokenExists(tokenId), "Token does not exist");

        AppStorage storage s = LibAppStorage.appStorage();
        string memory domain = s.tokenIdToDomain[tokenId];
        Domain memory domainInfo = s.domains[tokenId];
        bool isAI = s.isAISubdomain[tokenId];

        string memory imageURI = _generateImageURI(tokenId, domainInfo, isAI);

        string memory json = string(abi.encodePacked(
            '{"name":"', domain, '",',
            '"description":"', s.globalDescription, ' - ', domain, '",',
            '"image":"', imageURI, '",',
            '"external_url":"https://alsania.io/domain/', domain, '",',
            '"attributes":[',
                _buildAttributes(tokenId, domainInfo, isAI),
            ']}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function _generateImageURI(
        uint256 tokenId,
        Domain memory domainInfo,
        bool isAI
    ) private view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // If custom image set, generate SVG with frame overlay
        string memory customImage = bytes(domainInfo.imageURI).length > 0 
            ? domainInfo.imageURI 
            : "";

        string memory svg = LibSVG.generateSVG(tokenId, customImage, isAI);

        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        ));
    }

    function _buildAttributes(
        uint256 tokenId,
        Domain memory domainInfo,
        bool isAI
    ) private view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        uint256 evolutionLevel = s.evolutionLevels[tokenId];
        uint256 fragmentCount = s.tokenFragments[tokenId].length;

        string memory attrs = string(abi.encodePacked(
            '{"trait_type":"TLD","value":"', domainInfo.tld, '"},',
            '{"trait_type":"Type","value":"', 
                isAI ? "AI Badge" : (domainInfo.isSubdomain ? "Subdomain" : "Domain"), 
            '"},',
            '{"trait_type":"Evolution Level","value":', evolutionLevel.toString(), '},',
            '{"trait_type":"Fragments","value":', fragmentCount.toString(), '},',
            '{"trait_type":"Subdomains","value":', domainInfo.subdomainCount.toString(), '},',
            '{"trait_type":"Features","value":', _getFeatureCount(tokenId).toString(), '}'
        ));

        if (isAI) {
            string memory modelType = s.aiModelType[tokenId];
            uint256 capCount = _getCapabilityCount(tokenId);
            
            attrs = string(abi.encodePacked(
                attrs,
                ',{"trait_type":"AI Model","value":"', modelType, '"}',
                ',{"trait_type":"Capabilities","value":', capCount.toString(), '}'
            ));
        }

        return attrs;
    }

    function _getFeatureCount(uint256 tokenId) private view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 features = s.domainFeatures[tokenId];
        uint256 count = 0;

        while (features > 0) {
            if ((features & 1) == 1) {
                count++;
            }
            features >>= 1;
        }

        return count;
    }

    function _getCapabilityCount(uint256 tokenId) private view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        string[4] memory caps = ["ai_vision", "ai_communication", "ai_memory", "ai_reasoning"];
        uint256 count = 0;
        
        for (uint256 i = 0; i < caps.length; i++) {
            if (s.aiCapabilities[tokenId][caps[i]]) count++;
        }
        
        return count;
    }

    function contractURI() internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();

        string memory collectionName = bytes(s.name).length > 0
            ? s.name
            : "Alsania Enhanced Domains";

        string memory description = bytes(s.globalDescription).length > 0
            ? s.globalDescription
            : "Evolving domain identities with AI badge system and achievement fragments";

        string memory json = string(abi.encodePacked(
            '{"name":"', collectionName, '",',
            '"description":"', description, '",',
            '"image":"https://api.alsania.io/contract-image.png",',
            '"external_link":"https://alsania.io",',
            '"seller_fee_basis_points":250,',
            '"fee_recipient":"', _addressToString(s.feeCollector), '"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function _addressToString(address account) private pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(account)), 20);
    }
}
