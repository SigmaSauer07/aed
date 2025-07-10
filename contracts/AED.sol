// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./core/AEDCore.sol";
import "./modules/AEDMinting.sol";
import "./modules/AEDBridge.sol";
import "./modules/AEDRecovery.sol";
import "./modules/AEDMetadata.sol";
import "./modules/AEDReverse.sol";
import "./modules/AEDRegistry.sol";
import "./modules/AEDAdmin.sol";
contract AED is
    Initializable,
    UUPSUpgradeable,
    AEDCore,
    AEDRegistry,
    AEDMinting,
    AEDBridge,
    AEDRecovery,
    AEDMetadata,
    AEDReverse,
    ReentrancyGuardUpgradeable
{
    // Use constant for feature flags if possible
    uint8 public constant FEATURE_PROFILE     = 0x01;
    uint8 public constant FEATURE_REVERSE     = 0x02;
    uint8 public constant FEATURE_SUBDOMAINS  = 0x04;

    mapping(uint8 => uint256) public enhancementPrices;

    event FeatureEnabled(uint256 indexed tokenId, uint8 feature);
    event TLDPriceUpdated(string tld, uint256 price);
    event EnhancementPriceUpdated(uint8 feature, uint256 price);

    /// @notice Initializes the AED contract with payees and shares
    function initialize(address[] memory payees, uint256[] memory shares_) public initializer {
        __ERC721_init("Alsania Enhanced Domain", "AED");
        __PaymentSplitter_init(payees, shares_);
        __Pausable_init();
        __AEDCore_init("Alsania Enhanced Domain", "AED", payees, shares_);
        __UUPSUpgradeable_init();

        // TLD pricing
        setTLDPrice("aed", 0);
        setTLDPrice("07", 0);
        setTLDPrice("alsa", 0);
        setTLDPrice("alsania", 1 ether / 1000);
        setTLDPrice("fx",      1 ether / 1000);

        // Enhancement pricing
        enhancementPrices[FEATURE_SUBDOMAINS] = 2 ether / 1000;
    }

    /// @dev Only allow upgrades by UPGRADER_ROLE
    function _authorizeUpgrade(address newImpl) internal override(AEDCore, UUPSUpgradeable) onlyRole(UPGRADER_ROLE) {}

    /// @notice Purchase a feature for a domain
    function purchaseFeature(uint256 tokenId, uint8 feature) external payable nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not domain owner");
        require((domainFeatures[tokenId] & feature) == 0, "Already enabled");
        require(
            feature == FEATURE_PROFILE || 
            feature == FEATURE_REVERSE || 
            feature == FEATURE_SUBDOMAINS,
            "Invalid feature"
        );
        require(enhancementPrices[feature] != 0, "Feature not available");

        uint256 price = enhancementPrices[feature];
        require(msg.value >= price, "Insufficient payment");
        require(feeCollector != address(0), "Fee collector not set");

        // Effects before interactions (checks-effects-interactions pattern)
        domainFeatures[tokenId] |= feature;
        emit FeatureEnabled(tokenId, feature);

        Address.sendValue(payable(feeCollector), msg.value);
    }

    /// @notice Set the price for a feature enhancement
    function setEnhancementPrice(uint8 feature, uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            feature == FEATURE_PROFILE || 
            feature == FEATURE_REVERSE || 
            feature == FEATURE_SUBDOMAINS,
            "Invalid feature"
        );
        uint256 oldPrice = enhancementPrices[feature];
        if (oldPrice != price) {
            enhancementPrices[feature] = price;
            emit EnhancementPriceUpdated(feature, price);
        }
    }

    /// @notice Set the price for a TLD
    function setTLDPrice(string memory tld, uint256 price) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldPrice = tldPrices[tld];
        if (oldPrice != price) {
            tldPrices[tld] = price;
            emit TLDPriceUpdated(tld, price);
        }
    }

    /// @notice Get the price for a TLD
    function getTLDPrice(string memory tld) public view returns (uint256) {
        return tldPrices[tld];
    }

    /// @notice Set the fee collector address
    function setFeeCollector(address newFeeCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFeeCollector != address(0), "Zero address");
        if (feeCollector != newFeeCollector) {
            feeCollector = newFeeCollector;
        }
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AEDCore, AEDMetadata)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(AEDCore, AEDMetadata)
        returns (string memory)
    {
        return AEDMetadata.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(AEDCore)
    {
        super._burn(tokenId);
    }

    function _exists(uint256 tokenId)
        internal
        view
        override(AEDCore)
        returns (bool)
    {
        return AEDCore._exists(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override(AEDCore)
        returns (bool)
    {
        return AEDCore._isApprovedOrOwner(spender, tokenId);
    }
}