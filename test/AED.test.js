const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

const NAME = "Alsania Enhanced Domains";
const SYMBOL = "AED";
const SUBDOMAIN_FEATURE = "subdomain";

async function deployAED(feeCollector, admin) {
  const AEDImplementation = await ethers.getContractFactory("AEDImplementation");
  const proxy = await upgrades.deployProxy(
    AEDImplementation,
    [NAME, SYMBOL, feeCollector, admin],
    { initializer: "initialize", kind: "uups" }
  );
  await proxy.deployed();
  return proxy;
}

describe("AEDImplementation", function () {
  let owner;
  let user1;
  let user2;
  let feeCollector;
  let other;
  let aed;

  beforeEach(async function () {
    [owner, user1, user2, feeCollector, other] = await ethers.getSigners();
    aed = await deployAED(feeCollector.address, owner.address);
  });

  describe("deployment", function () {
    it("sets metadata and roles", async function () {
      expect(await aed.name()).to.equal(NAME);
      expect(await aed.symbol()).to.equal(SYMBOL);

      const adminRole = await aed.DEFAULT_ADMIN_ROLE();
      expect(await aed.hasRole(adminRole, owner.address)).to.be.true;
      expect(await aed.getFeeCollector()).to.equal(feeCollector.address);
    });

    it("normalizes TLD configuration", async function () {
      expect(await aed.isTLDActive("AED")).to.be.true;
      expect(await aed.isTLDFree("aed")).to.be.true;
      expect(await aed.getTLDPrice("ALSANIA")).to.equal(ethers.utils.parseEther("1"));
    });
  });

  describe("domain registration", function () {
    it("registers a free domain without payment", async function () {
      const tx = await aed.connect(user1).registerDomain("echo", "aed", false);
      await tx.wait();

      expect(await aed.ownerOf(1)).to.equal(user1.address);
      expect(await aed.getDomainByTokenId(1)).to.equal("echo.aed");
      expect(await aed.isRegistered("ECHO", "AED")).to.be.true;

      const tokenURI = await aed.tokenURI(1);
      expect(tokenURI).to.include("data:application/json;base64,");
    });

    it("collects payment for premium domains and routes revenue", async function () {
      const price = ethers.utils.parseEther("1");
      const collectorBefore = await ethers.provider.getBalance(feeCollector.address);
      const userBefore = await ethers.provider.getBalance(user1.address);

      const tx = await aed.connect(user1).registerDomain("atlas", "alsania", false, { value: price });
      const receipt = await tx.wait();

      const gasPrice = receipt.effectiveGasPrice || receipt.gasPrice;
      const gasSpent = receipt.gasUsed.mul(gasPrice);
      const collectorAfter = await ethers.provider.getBalance(feeCollector.address);
      const userAfter = await ethers.provider.getBalance(user1.address);

      expect(collectorAfter.sub(collectorBefore)).to.equal(price);
      expect(userBefore.sub(userAfter)).to.equal(price.add(gasSpent));

      expect(await aed.getTotalRevenue()).to.equal(price);
      expect(await aed.ownerOf(1)).to.equal(user1.address);
      expect(await aed.isRegistered("atlas", "alsania")).to.be.true;
    });

    it("enables subdomain feature when requested", async function () {
      const cost = ethers.utils.parseEther("2");
      await expect(
        aed.connect(user1).registerDomain("forge", "aed", true, { value: cost })
      ).to.not.be.reverted;

      expect(await aed.isFeatureEnabled(1, SUBDOMAIN_FEATURE)).to.be.true;
      expect(await aed.isDomainEnhanced("forge.aed")).to.be.true;
    });

    it("reverts on invalid TLD", async function () {
      await expect(
        aed.connect(user1).registerDomain("invalid", "?", false)
      ).to.be.revertedWith("Invalid TLD format");
    });

    it("normalizes mixed-case inputs before persistence", async function () {
      const tx = await aed.connect(user1).registerDomain("NeOn", "Aed", false);
      await tx.wait();

      expect(await aed.getDomainByTokenId(1)).to.equal("neon.aed");
      expect(await aed.isRegistered("NEON", "AED")).to.be.true;
      expect(await aed.getTokenIdByDomain("NEON.AED")).to.equal(1);
    });

    it("rejects domain names containing whitespace", async function () {
      await expect(
        aed.connect(user1).registerDomain("bad name", "aed", false)
      ).to.be.revertedWith("Invalid name format");
    });
  });

  describe("subdomains", function () {
    beforeEach(async function () {
      const cost = ethers.utils.parseEther("2");
      await aed.connect(user1).registerDomain("root", "aed", true, { value: cost });
    });

    it("mints subdomains and enforces tiered fees", async function () {
      await expect(aed.connect(user1).mintSubdomain(1, "alpha", { value: 0 })).to.not.be.reverted;
      await expect(aed.connect(user1).mintSubdomain(1, "beta", { value: 0 })).to.not.be.reverted;

      const nextFee = await aed.calculateSubdomainFee(1);
      expect(nextFee).to.equal(ethers.utils.parseEther("0.1"));

      await expect(
        aed.connect(user1).mintSubdomain(1, "gamma", { value: ethers.utils.parseEther("0.1") })
      ).to.not.be.reverted;

      expect(await aed.ownerOf(4)).to.equal(user1.address);
      expect(await aed.getDomainByTokenId(4)).to.equal("gamma.root.aed");
    });

    it("blocks unauthorised subdomain minting", async function () {
      await expect(
        aed.connect(user2).mintSubdomain(1, "hijack")
      ).to.be.revertedWith("Not parent domain owner");
    });
  });

  describe("batch operations", function () {
    it("registers multiple domains and charges combined fee", async function () {
      const names = ["alpha", "beta"];
      const tlds = ["aed", "alsania"];
      const flags = [false, false];
      const payment = ethers.utils.parseEther("1");

      await expect(
        aed.connect(user1).batchRegisterDomains(names, tlds, flags, { value: payment })
      ).to.not.be.reverted;

      expect(await aed.ownerOf(1)).to.equal(user1.address);
      expect(await aed.ownerOf(2)).to.equal(user1.address);
      expect(await aed.getTotalRevenue()).to.equal(payment);
    });
  });

  describe("reverse resolution", function () {
    beforeEach(async function () {
      await aed.connect(user1).registerDomain("signal", "aed", false);
    });

    it("sets and clears reverse records with normalization", async function () {
      await aed.connect(user1).setReverse("SIGNAL.AED");
      expect(await aed.getReverse(user1.address)).to.equal("signal.aed");
      expect(await aed.getReverseOwner("signal.aed")).to.equal(user1.address);

      await aed.connect(user1).clearReverse();
      expect(await aed.getReverse(user1.address)).to.equal("");
    });
  });

  describe("enhancements", function () {
    beforeEach(async function () {
      await aed.connect(user1).registerDomain("upgrade", "aed", false);
    });

    it("purchases subdomain feature", async function () {
      const price = await aed.getFeaturePrice(SUBDOMAIN_FEATURE);
      await aed.connect(user1).purchaseFeature(1, SUBDOMAIN_FEATURE, { value: price });
      expect(await aed.isFeatureEnabled(1, SUBDOMAIN_FEATURE)).to.be.true;
      expect(await aed.getTotalRevenue()).to.equal(price);
    });

    it("upgrades external domain", async function () {
      const price = await aed.getFeaturePrice("byo");
      await expect(
        aed.connect(user1).upgradeExternalDomain("External.Domain", { value: price })
      ).to.not.be.reverted;

      expect(await aed.isDomainEnhanced("external.domain")).to.be.true;
    });
  });

  describe("admin controls", function () {
    it("updates fees, tlds and fee recipient", async function () {
      const feeRole = await aed.FEE_MANAGER_ROLE();
      const tldRole = await aed.TLD_MANAGER_ROLE();

      await aed.grantRole(feeRole, owner.address);
      await aed.grantRole(tldRole, owner.address);

      await aed.updateFee(SUBDOMAIN_FEATURE, ethers.utils.parseEther("3"));
      expect(await aed.getFee(SUBDOMAIN_FEATURE)).to.equal(ethers.utils.parseEther("3"));
      expect(await aed.getFeaturePrice(SUBDOMAIN_FEATURE)).to.equal(ethers.utils.parseEther("3"));

      await aed.configureTLD("NEW", true, ethers.utils.parseEther("0.5"));
      expect(await aed.isTLDActive("new")).to.be.true;
      expect(await aed.getTLDPrice("NeW")).to.equal(ethers.utils.parseEther("0.5"));

      await aed.updateFeeRecipient(other.address);
      expect(await aed.getFeeCollector()).to.equal(other.address);
    });

    it("updates optional fee entries without enabling enhancements", async function () {
      const feeRole = await aed.FEE_MANAGER_ROLE();
      await aed.grantRole(feeRole, owner.address);

      const customFee = ethers.utils.parseEther("5");
      await aed.updateFee("custom-feature", customFee);

      expect(await aed.getFee("custom-feature")).to.equal(customFee);
      expect(await aed.getFeaturePrice("custom-feature")).to.equal(0);
    });

    it("pauses and unpauses minting", async function () {
      await aed.pause();
      await expect(
        aed.connect(user1).registerDomain("halt", "aed", false)
      ).to.be.revertedWith("Contract paused");

      await aed.unpause();
      await expect(
        aed.connect(user1).registerDomain("resume", "aed", false)
      ).to.not.be.reverted;
    });
  });

  describe("transfers", function () {
    it("updates ownership lists and reverse records", async function () {
      await aed.connect(user1).registerDomain("shift", "aed", false);
      await aed.connect(user1).setReverse("shift.aed");

      await aed.connect(user1).transferFrom(user1.address, user2.address, 1);

      expect(await aed.ownerOf(1)).to.equal(user2.address);
      expect(await aed.getReverse(user1.address)).to.equal("");
      expect(await aed.getReverse(user2.address)).to.equal("shift.aed");

      const domainsUser1 = await aed.getUserDomains(user1.address);
      const domainsUser2 = await aed.getUserDomains(user2.address);
      expect(domainsUser1.length).to.equal(0);
      expect(domainsUser2.length).to.equal(1);
    });
  });

  describe("upgradeability", function () {
    it("upgrades to a new implementation without data loss", async function () {
      await aed.connect(user1).registerDomain("legacy", "aed", false);
      const proxyAddress = aed.address;

      const AEDImplementationV2 = await ethers.getContractFactory("AEDImplementationV2");
      const upgraded = await upgrades.upgradeProxy(proxyAddress, AEDImplementationV2);
      await upgraded.deployed();

      expect(await upgraded.ownerOf(1)).to.equal(user1.address);
      expect(await upgraded.version()).to.equal("v2");
    });
  });
});
