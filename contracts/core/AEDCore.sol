// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "../libraries/LibAppStorage.sol";
import "./AEDConstants.sol";
import "./interfaces/IAEDCore.sol";

/**
 * @title AEDCore
 * @dev Core contract implementation with roles, fees, and pause functionality using AppStorage
 */
abstract contract AEDCore is
    Initializable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    AEDConstants,
    IAEDCore
{
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);

    function s() internal pure returns (AppStorage storage store) {
        return LibAppStorage.getStorage();
    }

    function __AEDCore_init(
        string memory name_,
        string memory symbol_,
        address admin
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __AccessControl_init();
        __Pausable_init();

        s().nextTokenId = 1;
        s().royaltyBps = DEFAULT_ROYALTY_BPS;
        s().maxSubdomains = DEFAULT_MAX_SUBDOMAINS;
        s().basePrice = DEFAULT_BASE_PRICE;
        s().futureUint256[0] = DEFAULT_MULTIPLIER; // Using futureUint256 mapping for multiplier

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(TLD_MANAGER_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function name() public view override(ERC721Upgradeable, IAEDCore) returns (string memory) {
        return super.name();
    }

    function symbol() public view override(ERC721Upgradeable, IAEDCore) returns (string memory) {
        return super.symbol();
    }

    function ownerOf(uint256 tokenId) public view override(ERC721Upgradeable, IAEDCore) returns (address) {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function balanceOf(address owner) public view override(ERC721Upgradeable, IAEDCore) returns (uint256) {
        return ERC721Upgradeable.balanceOf(owner);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return super._ownerOf(tokenId) != address(0);
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721Upgradeable) {
        require(to != address(0), "ERC721: mint to zero address");
        require(!_exists(tokenId), "ERC721: already minted");

        _update(to, tokenId, address(0));
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        address owner = ownerOf(tokenId);
        
        _update(address(0), tokenId, owner);
        
        // Clean up domain-specific data
        delete s().domains[tokenId];
        delete s().domainFeatures[tokenId];
    }

    // Fix: Implement required override functions
    function hasRole(bytes32 role, address account) public view override(AccessControlUpgradeable, IAEDCore) returns (bool) {
        return super.hasRole(role, account);
    }

    function paused() public view override(PausableUpgradeable, IAEDCore) returns (bool) {
        return super.paused();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, IAEDCore) returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return s().tokenURIs[tokenId];
    }

    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
        s().paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpause() external onlyRole(PAUSER_ROLE) whenPaused {
        _unpause();
        s().paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function setFeeCollector(address newCollector) external onlyRole(ADMIN_ROLE) {
        require(newCollector != address(0), "Invalid collector");
        s().feeCollector = newCollector;
    }

    function getFeeCollector() external view override returns (address) {
        return s().feeCollector;
    }

    function setRoyaltyBps(uint256 newBps) external onlyRole(ADMIN_ROLE) {
        require(newBps <= 10000, "Royalty too high");
        s().royaltyBps = newBps;
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        pure
        returns (address, uint256)
    {
        return (s().feeCollector, (salePrice * s().royaltyBps) / 10000);
    }

    function getDomain(uint256 tokenId) external view returns (Domain memory) {
        require(_exists(tokenId), "Token does not exist");
        return s().domains[tokenId];
    }

    function getDomainFeatures(uint256 tokenId) external view override returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return s().domainFeatures[tokenId];
    }

    function getNextTokenId() external view override returns (uint256) {
        return s().nextTokenId;
    }

    // Override totalSupply to use our custom storage
    function totalSupply() public view override returns (uint256) {
        return s().nextTokenId - 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, IAEDCore, AccessControlUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId ||
               interfaceId == type(IAEDCore).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721EnumerableUpgradeable)
        whenNotPaused
        returns (address)
    {
        address from = super._update(to, tokenId, auth);
        
        // Update domain owner if it's a transfer (not mint/burn)
        if (to != address(0) && from != address(0)) {
            s().domains[tokenId].owner = to;
        }
        
        return from;
    }

    // Implement missing IAEDCore functions
    function domains(uint256 tokenId) external view override returns (
        string memory domainName,
        string memory domainTld,
        string memory profileURI,
        string memory imageURI,
        uint256 subdomainCount,
        uint256 mintFee,
        uint64 expiresAt,
        bool feeEnabled,
        bool isSubdomain,
        address owner
    ) {
        require(_exists(tokenId), "Token does not exist");
        Domain memory domain = s().domains[tokenId];
        return (
            domain.name,
            domain.tld,
            domain.profileURI,
            domain.imageURI,
            domain.subdomainCount,
            domain.mintFee,
            domain.expiresAt,
            domain.feeEnabled,
            domain.isSubdomain,
            domain.owner
        );
    }
    
    // Implement required IAEDCore functions with empty implementations
    // These should be implemented by derived contracts
    function supportsModule(bytes32) external view virtual override returns (bool) {
        return false;
    }
    
    function moduleId() external pure virtual override returns (bytes32) {
        return bytes32(0);
    }
    
    function moduleVersion() external pure virtual override returns (uint256) {
        return 0;
    }
    
    function dependencies() external pure virtual override returns (bytes32[] memory) {
        return new bytes32[](0);
    }
    
    function initialize(bytes calldata) external virtual override {
        // To be implemented by derived contracts
    }
    
    function isEnabled() external view virtual override returns (bool) {
        return !paused();
    }
    
    function enable(bool enabled) external virtual override onlyRole(PAUSER_ROLE) {
        if (enabled) {
            if (paused()) {
                _unpause();
                s().paused = false;
                emit ContractUnpaused(msg.sender);
            }
        } else {
            if (!paused()) {
                _pause();
                s().paused = true;
                emit ContractPaused(msg.sender);
            }
        }
    }
    // gap slots are reserved for future values (currently unused)
}