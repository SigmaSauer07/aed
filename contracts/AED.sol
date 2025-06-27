// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./core/AEDCore.sol";
import "./modules/AEDMinting.sol";
import "./modules/AEDBridge.sol";
import "./modules/AEDRecovery.sol";
import "./modules/AEDMetadata.sol";
import "./modules/AEDReverse.sol";

contract AED is
    Initializable,
    UUPSUpgradeable,
    AEDCore,
    AEDMinting,
    AEDBridge,
    AEDRecovery,
    AEDMetadata,
    AEDReverse
{
    function initialize(address[] memory payees, uint256[] memory shares_) public initializer {
        __AEDCore_init("Alsania Enhanced Domain", "AED", payees, shares_);
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE,         msg.sender);
        _grantRole(UPGRADER_ROLE,      msg.sender);
        _grantRole(BRIDGE_MANAGER,     msg.sender);

        nextTokenId  = 1;
        renewalPrice = 0.01 ether;
        royaltyBps   = 500;
        feeCollector = 0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43;
    }

    function _authorizeUpgrade(address newImpl) internal override onlyRole(UPGRADER_ROLE) {}
    

    // Feature constants
    uint8 public constant FEATURE_PROFILE    = 0x01;
    uint8 public constant FEATURE_REVERSE    = 0x02;
    uint8 public constant FEATURE_SUBDOMAINS = 0x04;

    // Feature flag storage
    mapping(uint256 => uint8) public domainFeatures;

    // Modifier to check feature activation
    modifier hasFeature(uint256 tokenId, uint8 feature) {
        require((domainFeatures[tokenId] & feature) != 0, "Feature not enabled");
        _;
    }

    // Function to purchase/enable enhancements
    function purchaseFeature(uint256 tokenId, uint8 feature) external payable {
        require(ownerOf(tokenId) == msg.sender, "Not domain owner");
        require((domainFeatures[tokenId] & feature) == 0, "Already enabled");

        if (feature == FEATURE_SUBDOMAINS) {
            require(msg.value >= 2 ether / 1000, "Insufficient payment");
        payable(feeCollector).transfer(msg.value); // $2 in MATIC
        }

        domainFeatures[tokenId] |= feature;
    }


    address public feeCollector;

    function setFeeCollector(address newFeeCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeCollector = newFeeCollector;
    }


/* -------------------------------------------------------------------------- */
    /*                           Interface & Metadata                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Merge the `supportsInterface` provided by AEDCore and AEDMetadata,
     *      then advertise IERC2981 as well.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AEDCore, AEDMetadata)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Resolve tokenURI ambiguity by explicitly selecting both parent contracts
     *      that implement it.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorageUpgradeable, AEDMetadata)
        returns (string memory)
    {
        return AEDMetadata.tokenURI(tokenId);
    }
}