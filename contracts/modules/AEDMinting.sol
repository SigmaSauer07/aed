// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../core/CoreState.sol";
import "./AEDRegistry.sol";

abstract contract AEDMinting is CoreState, AEDRegistry {
    using Strings for uint256;
    
    event SubdomainMinted(address indexed minter, uint256 indexed parentId, uint256 indexed subId, string label, string fullName);
    
    // Custom errors
    error DomainTaken();
    error InvalidTLD();
    error InsufficientPayment();
    error SubdomainTaken();
    error TLDNotRegistered();
    error ParentDoesNotExist();
    error NotParentOwner();
    error InvalidParentId();
    error SubdomainsDisabledForParent();
    error PaymentFailed();
    error InvalidNameLength();
    error InvalidNameFormat();
    error EmptyLabel();
    error LabelTooLong();
    error BYODomainNotAllowed();
    error RefundFailed();

    // Constants
    uint256 public constant SUBDOMAIN_UNLOCK_PRICE = 0.002 ether;
    uint256 public constant SUBDOMAIN_UNLOCK_PRICE_BYO = 0.005 ether;
    uint256 public constant MAX_SUBDOMAINS = 100;
    uint256 public constant MIN_NAME_LENGTH = 3;
    uint256 public constant MAX_NAME_LENGTH = 64;
    
    // State
    mapping(uint256 => mapping(string => bool)) public mintedSubdomain;
    uint256 public subdomainMaxLimit;
    uint256 public subdomainBasePrice;
    uint256 public subdomainPriceMultiplier;

    function __AEDMinting_init() internal onlyInitializing {
        __ReentrancyGuard_init();
        subdomainMaxLimit = 20;
        subdomainBasePrice = 0.001 ether;
        subdomainPriceMultiplier = 2;
        
        // Set initial TLDs
        super.setTLDPrice("aed", 0);
        super.setTLDPrice("alsa", 0);
        super.setTLDPrice("07", 0);
        super.setTLDPrice("alsania", 0.001 ether);
        super.setTLDPrice("fx", 0.001 ether);
        super.setTLDPrice("echo", 0.001 ether);
    }
    
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        _validateName(name);
        if (tldPrices[tld] == 0 && !_isFreeTLD(tld)) revert InvalidTLD();

        string memory normalizedName = _normalizeName(name);
        string memory fullName = string(abi.encodePacked(normalizedName, ".", tld));
        if (registered[fullName]) revert DomainTaken();

        uint256 totalCost = _calculateRegistrationCost(tld, enableSubdomains);
        if (msg.value < totalCost) revert InsufficientPayment();
        _processPayment(totalCost);

        uint256 newId = nextTokenId++;
        _safeMint(msg.sender, newId);

        domains[newId] = Domain({
            name: normalizedName,
            tld: tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            feeEnabled: false,
            expiresAt: 0,
            isSubdomain: false,
            owner: msg.sender
        });

        registered[fullName] = true;

        if (enableSubdomains) {
            _setFeature(newId, FEATURE_SUBDOMAINS);
        }

        if (msg.value > totalCost) {
            _refundExcessPayment(msg.value - totalCost);
        }

        emit DomainRegistered(newId, fullName);
        return newId;
    }

    function mintSubdomain(
        uint256 parentId,
        string calldata label
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        if (!_exists(parentId)) revert ParentDoesNotExist();
        if (ownerOf(parentId) != msg.sender) revert NotParentOwner();
        if (domains[parentId].isSubdomain) revert InvalidParentId();
        if (domainFeatures[parentId] & FEATURE_SUBDOMAINS == 0) revert SubdomainsDisabledForParent();

        Domain storage parentDomain = domains[parentId];
        bytes memory labelBytes = bytes(label);
        uint256 labelLength = labelBytes.length;

        if (!byoDomains[parentDomain.tld]) revert BYODomainNotAllowed();
        if (labelLength == 0) revert EmptyLabel();
        _validateLabel(labelBytes);
        if (labelLength < MIN_NAME_LENGTH) revert InvalidNameLength();
        if (labelLength > MAX_NAME_LENGTH) revert LabelTooLong();

        string memory normalizedLabel = _normalizeName(label);
        string memory parentName = string(abi.encodePacked(parentDomain.name, ".", parentDomain.tld));
        string memory fullName = string(abi.encodePacked(normalizedLabel, ".", parentName));

        if (mintedSubdomain[parentId][normalizedLabel]) revert SubdomainTaken();
        if (registered[fullName]) revert DomainTaken();
        if (domains[parentId].subdomainCount >= subdomainMaxLimit) revert("Max subdomains");

        uint256 fee = calculateSubdomainFee(parentId);
        if (msg.value < fee) revert InsufficientPayment();
        _processPayment(fee);

        uint256 newId = nextTokenId++;
        _safeMint(msg.sender, newId);

        domains[newId] = Domain({
            name: normalizedLabel,
            tld: parentName,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            feeEnabled: false,
            expiresAt: 0,
            isSubdomain: true,
            owner: msg.sender
        });

        mintedSubdomain[parentId][normalizedLabel] = true;
        registered[fullName] = true;
        domains[parentId].subdomainCount++;

        emit SubdomainCreated(parentId, newId, fullName);
        emit SubdomainMinted(msg.sender, parentId, newId, normalizedLabel, fullName);
        return newId;
    }

    function calculateSubdomainFee(uint256 parentId) public view returns (uint256) {
        uint256 count = domains[parentId].subdomainCount;
        return count < 2 ? 0 : subdomainBasePrice * (subdomainPriceMultiplier ** (count - 1));
    }


    function updateSubdomainSettings(
        uint256 newMax,
        uint256 newBasePrice,
        uint256 newMultiplier
    ) external override(ADMIN_ROLE) {
        subdomainMaxLimit = newMax;
        subdomainBasePrice = newBasePrice;
        subdomainPriceMultiplier = newMultiplier;
        emit super.SubdomainSettingsUpdated(newMax, newBasePrice, newMultiplier);
    }

    // Internal functions
    function _validateName(string memory name) internal pure {
        bytes memory nameBytes = bytes(name);
        uint256 nameLength = nameBytes.length;
        if (nameLength < MIN_NAME_LENGTH) revert InvalidNameLength();
        if (nameLength > MAX_NAME_LENGTH) revert LabelTooLong();

        for (uint256 i = 0; i < nameLength; i++) {
            bytes1 char = nameBytes[i];
            if (
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char >= 0x30 && char <= 0x39) && // 0-9
                char != 0x2D // hyphen (-)
            ) {
                revert InvalidNameFormat();
            }
        }
    }

    function _validateLabel(bytes memory labelBytes) internal pure {
        uint256 labelLength = labelBytes.length;
        if (labelLength == 0) revert EmptyLabel();
        if (labelBytes[0] == '-' || labelBytes[labelLength - 1] == '-') {
            revert InvalidNameFormat();
        }
    }

    function _normalizeName(string memory name) internal pure returns (string memory) {
        bytes memory nameBytes = bytes(name);
        bytes memory lowerBytes = new bytes(nameBytes.length);

        for (uint256 i = 0; i < nameBytes.length; i++) {
            bytes1 char = nameBytes[i];
            if (char >= 0x41 && char <= 0x5A) { // A-Z
                lowerBytes[i] = bytes1(uint8(char) + 32);
            } else {
                lowerBytes[i] = char;
            }
        }
        return string(lowerBytes);
    }

    function _calculateRegistrationCost(
        string memory tld,
        bool enableSubdomains
    ) internal view returns (uint256) {
        uint256 basePrice = tldPrices[tld];
        uint256 subdomainFee = enableSubdomains ?
            (byoDomains[tld] ? SUBDOMAIN_UNLOCK_PRICE_BYO : SUBDOMAIN_UNLOCK_PRICE) :
            0;
        return basePrice + subdomainFee;
    }

    function _processPayment(uint256 amount) internal {
        if (amount > 0) {
            (bool success, ) = payable(feeCollector).call{value: amount}("");
            if (!success) revert PaymentFailed();
        }
    }

    function _refundExcessPayment(uint256 amount) internal {
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert RefundFailed();
    }

    function _isFreeTLD(string memory tld) internal pure returns (bool) {
        bytes32 tldHash = keccak256(bytes(tld));
        return 
            tldHash == keccak256("aed") ||
            tldHash == keccak256("alsa") ||
            tldHash == keccak256("07");
    }
}