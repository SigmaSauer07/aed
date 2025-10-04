const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("AEDImplementation", function () {
  let aed;
  let owner;
  let user1;
  let user2;
  let feeCollector;

  let ADMIN_ROLE;
  let FEE_MANAGER_ROLE;
  let TLD_MANAGER_ROLE;

  before(async () => {
    [owner, user1, user2, feeCollector] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const AEDImplementation = await ethers.getContractFactory("AEDImplementation");
    aed = await upgrades.deployProxy(
      AEDImplementation,
      ["Alsania Enhanced Domains", "AED", feeCollector.address, owner.address],
      {
        initializer: "initialize",
        kind: "uups",
      },
    );

    ADMIN_ROLE = await aed.ADMIN_ROLE();
    FEE_MANAGER_ROLE = await aed.FEE_MANAGER_ROLE();
    TLD_MANAGER_ROLE = await aed.TLD_MANAGER_ROLE();
  });

  async function subdomainPrice() {
    return BigInt(await aed.getFeaturePrice("subdomain"));
  }

  async function byoPrice() {
    return BigInt(await aed.getFeaturePrice("byo"));
  }

  async function tldPrice(tld) {
    return BigInt(await aed.getTLDPrice(tld));
  }

  describe("Deployment", () => {
    it("initializes core parameters", async () => {
      expect(await aed.name()).to.equal("Alsania Enhanced Domains");
      expect(await aed.symbol()).to.equal("AED");
      expect(await aed.getFeeCollector()).to.equal(feeCollector.address);
      expect(await aed.hasRole(ADMIN_ROLE, owner.address)).to.equal(true);
    });

    it("sets default TLD configuration and feature catalog", async () => {
      expect(await aed.isTLDActive("aed")).to.equal(true);
      expect(await aed.isTLDActive("alsania")).to.equal(true);
      const catalog = await aed.getAvailableFeatures();
      expect(catalog).to.deep.equal(["subdomain", "metadata", "reverse", "bridge"]);
    });

    it("exposes default pricing", async () => {
      expect(await tldPrice("alsania")).to.equal(ethers.parseEther("1"));
      expect(await subdomainPrice()).to.equal(ethers.parseEther("2"));
      expect(await byoPrice()).to.equal(ethers.parseEther("5"));
    });
  });

  describe("Domain registration", () => {
    it("mints free domains without payment", async () => {
      await expect(aed.connect(user1).registerDomain("echo", "aed", false))
        .to.emit(aed, "Transfer")
        .withArgs(ethers.ZeroAddress, user1.address, 1n);

      expect(await aed.ownerOf(1n)).to.equal(user1.address);
      expect(await aed.isRegistered("echo", "aed")).to.equal(true);
    });

    it("charges for paid TLDs", async () => {
      const price = await tldPrice("alsania");
      await aed.connect(user1).registerDomain("prime", "alsania", false, { value: price });
      expect(await aed.ownerOf(1n)).to.equal(user1.address);
    });

    it("supports registration with enhancements", async () => {
      const enhancement = await subdomainPrice();
      await aed.connect(user1).registerDomain("builder", "aed", true, { value: enhancement });
      expect(await aed.isFeatureEnabled(1n, "subdomain")).to.equal(true);
    });

    it("normalizes names and TLDs", async () => {
      await aed.connect(user1).registerDomain("Test", "AED", false);
      expect(await aed.isRegistered("test", "aed")).to.equal(true);
      expect(await aed.getDomainByTokenId(1n)).to.equal("test.aed");
    });

    it("rejects duplicate registrations", async () => {
      await aed.connect(user1).registerDomain("echo", "aed", false);
      await expect(aed.connect(user2).registerDomain("echo", "aed", false)).to.be.revertedWith("Domain already exists");
    });

    it("rejects insufficient payment", async () => {
      const price = await tldPrice("alsania");
      await expect(
        aed.connect(user1).registerDomain("underpay", "alsania", false, { value: price - 1n }),
      ).to.be.revertedWith("Insufficient payment");
    });
  });

  describe("Subdomains", () => {
    beforeEach(async () => {
      const enhancement = await subdomainPrice();
      await aed.connect(user1).registerDomain("root", "aed", true, { value: enhancement });
    });

    it("mints subdomains when enabled", async () => {
      await expect(aed.connect(user1).mintSubdomain(1n, "alpha"))
        .to.emit(aed, "Transfer")
        .withArgs(ethers.ZeroAddress, user1.address, 2n);
      expect(await aed.ownerOf(2n)).to.equal(user1.address);
    });

    it("calculates progressive subdomain fees", async () => {
      expect(await aed.calculateSubdomainFee(1n)).to.equal(0n);
      await aed.connect(user1).mintSubdomain(1n, "one");
      expect(await aed.calculateSubdomainFee(1n)).to.equal(0n);
      await aed.connect(user1).mintSubdomain(1n, "two");
      expect(await aed.calculateSubdomainFee(1n)).to.equal(ethers.parseEther("0.1"));
    });

    it("prevents creating subdomains without permission", async () => {
      await aed.connect(user2).registerDomain("solo", "aed", false);
      await expect(aed.connect(user2).mintSubdomain(2n, "child")).to.be.revertedWith("Subdomains not enabled");
    });
  });

  describe("Metadata", () => {
    beforeEach(async () => {
      await aed.connect(user1).registerDomain("meta", "aed", false);
    });

    it("provides default profile metadata", async () => {
      const uri = await aed.getProfileURI(1n);
      expect(uri).to.not.equal("");
      expect(uri.startsWith("data:application/json;base64,")).to.equal(true);
    });

    it("updates profile and image URIs", async () => {
      const profile = "https://ipfs.example/profile.json";
      const image = "ipfs://image.png";
      await aed.connect(user1).setProfileURI(1n, profile);
      await aed.connect(user1).setImageURI(1n, image);
      expect(await aed.getProfileURI(1n)).to.equal(profile);
      expect(await aed.getImageURI(1n)).to.equal(image);
    });

    it("returns a tokenURI with embedded metadata", async () => {
      const tokenURI = await aed.tokenURI(1n);
      expect(tokenURI.startsWith("data:application/json;base64,")).to.equal(true);
    });
  });

  describe("Reverse resolution", () => {
    beforeEach(async () => {
      await aed.connect(user1).registerDomain("reverse", "aed", false);
    });

    it("sets and clears reverse records", async () => {
      await aed.connect(user1).setReverse("reverse.aed");
      expect(await aed.getReverse(user1.address)).to.equal("reverse.aed");
      await aed.connect(user1).clearReverse();
      expect(await aed.getReverse(user1.address)).to.equal("");
    });
  });

  describe("Feature enhancements", () => {
    beforeEach(async () => {
      await aed.connect(user1).registerDomain("feature", "aed", false);
    });

    it("enables subdomain feature", async () => {
      const price = await subdomainPrice();
      await aed.connect(user1).enableSubdomainFeature(1n, { value: price });
      expect(await aed.isFeatureEnabled(1n, "subdomain")).to.equal(true);
    });

    it("prevents double payment for the same feature", async () => {
      const price = await subdomainPrice();
      await aed.connect(user1).enableSubdomainFeature(1n, { value: price });
      await expect(
        aed.connect(user1).enableSubdomainFeature(1n, { value: price }),
      ).to.be.revertedWith("Feature already enabled");
    });

    it("allows purchasing metadata feature", async () => {
      const price = await aed.getFeaturePrice("metadata");
      await aed.connect(user1).purchaseFeature(1n, "metadata", { value: price });
      expect(await aed.isFeatureEnabled(1n, "metadata")).to.equal(true);
    });

    it("upgrades external domains using BYO pricing", async () => {
      const price = await byoPrice();
      await expect(aed.connect(user1).upgradeExternalDomain("example.eth", { value: price }))
        .to.emit(aed, "FeaturePurchased");
    });
  });

  describe("Batch registration", () => {
    it("registers multiple domains and refunds excess", async () => {
      const names = ["one", "two"];
      const tlds = ["aed", "alsania"];
      const enable = [false, false];
      const cost = await tldPrice("alsania");

      const balanceBefore = await ethers.provider.getBalance(user1.address);
      const tx = await aed.connect(user1).batchRegisterDomains(names, tlds, enable, { value: cost + ethers.parseEther("1") });
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * receipt.gasPrice;
      const balanceAfter = await ethers.provider.getBalance(user1.address);

      expect(await aed.ownerOf(1n)).to.equal(user1.address);
      expect(await aed.ownerOf(2n)).to.equal(user1.address);
      expect(balanceBefore - balanceAfter - gasUsed).to.equal(cost);
    });
  });

  describe("Admin controls", () => {
    it("updates feature pricing via fee manager", async () => {
      await aed.connect(owner).grantRole(FEE_MANAGER_ROLE, owner.address);
      const newPrice = ethers.parseEther("3");
      await aed.connect(owner).updateFee("subdomain", newPrice);
      expect(await aed.getFeaturePrice("subdomain")).to.equal(newPrice);
    });

    it("configures TLDs with normalized input", async () => {
      await aed.connect(owner).grantRole(TLD_MANAGER_ROLE, owner.address);
      await aed.connect(owner).configureTLD("ECHO", true, ethers.parseEther("2"));
      expect(await aed.isTLDActive("echo")).to.equal(true);
      expect(await aed.getTLDPrice("echo")).to.equal(ethers.parseEther("2"));
    });

    it("pauses and unpauses the contract", async () => {
      await aed.connect(owner).pause();
      await expect(aed.connect(user1).registerDomain("pause", "aed", false)).to.be.revertedWith("Contract paused");
      await aed.connect(owner).unpause();
      await aed.connect(user1).registerDomain("resume", "aed", false);
    });

    it("prevents unauthorized admin operations", async () => {
      await expect(aed.connect(user1).pause()).to.be.revertedWith("Not admin");
    });
  });

  describe("Transfers", () => {
    beforeEach(async () => {
      await aed.connect(user1).registerDomain("transfer", "aed", false);
      await aed.connect(user1).setReverse("transfer.aed");
    });

    it("transfers domains and updates reverse records", async () => {
      await aed.connect(user1).transferFrom(user1.address, user2.address, 1n);
      expect(await aed.ownerOf(1n)).to.equal(user2.address);
      expect(await aed.getReverse(user1.address)).to.equal("");
      expect(await aed.getReverse(user2.address)).to.equal("transfer.aed");
    });
  });
});
