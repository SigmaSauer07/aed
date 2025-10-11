const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = require("ethers");

const PROVIDER_URL = "http://127.0.0.1:8545";

async function buildProvider() {
    return new ethers.JsonRpcProvider(PROVIDER_URL);
}

async function deployProxyContract(factory, initArgs, deployer) {
    const implementation = await factory.deploy();
    await implementation.waitForDeployment();

    const implAddress = await implementation.getAddress();
    const initData = implementation.interface.encodeFunctionData("initialize", initArgs);

    const proxyArtifact = await hre.artifacts.readArtifact("ERC1967Proxy");
    const proxyFactory = new ethers.ContractFactory(proxyArtifact.abi, proxyArtifact.bytecode, deployer);
    const proxy = await proxyFactory.deploy(implAddress, initData);
    await proxy.waitForDeployment();

    const proxyAddress = await proxy.getAddress();
    const proxyInstance = new ethers.Contract(proxyAddress, factory.interface, deployer);

    return { implementation, proxy, instance: proxyInstance };
}

async function freshFixture() {
    await hre.network.provider.send("hardhat_reset");
    const provider = await buildProvider();

    const owner = await provider.getSigner(0);
    const user1 = await provider.getSigner(1);
    const user2 = await provider.getSigner(2);
    const feeCollector = await provider.getSigner(3);

    const aedArtifact = await hre.artifacts.readArtifact("AEDImplementation");
    const factory = new ethers.ContractFactory(aedArtifact.abi, aedArtifact.bytecode, owner);

    const { instance: aed } = await deployProxyContract(factory, [
        "Alsania Enhanced Domains",
        "AED",
        await feeCollector.getAddress(),
        await owner.getAddress(),
    ], owner);

    return { provider, owner, user1, user2, feeCollector, aed };
}

async function expectRevert(promise, message) {
    try {
        await promise;
        throw new Error("Expected revert");
    } catch (error) {
        const reason = error?.shortMessage || error?.info?.error?.message || error?.message || "";
        expect(reason).to.include(message);
    }
}

describe("AED - Alsania Enhanced Domains", function () {
    this.timeout(120000);

    describe("Deployment & Initialization", function () {
        it("configures core metadata and roles", async function () {
            const { aed, owner, feeCollector } = await freshFixture();
            expect(await aed.name()).to.equal("Alsania Enhanced Domains");
            expect(await aed.symbol()).to.equal("AED");
            expect(await aed.hasRole(await aed.ADMIN_ROLE(), await owner.getAddress())).to.equal(true);
            expect(await aed.getFeeCollector()).to.equal(await feeCollector.getAddress());
            expect(await aed.contractURI()).to.include("data:application/json;base64,");
            expect(await aed.version()).to.equal("1.0.0");
        });

        it("preloads Alsania TLD configuration", async function () {
            const { aed } = await freshFixture();
            const tlds = ["aed", "alsa", "07", "alsania", "fx", "echo"];
            for (const tld of tlds) {
                expect(await aed.isTLDActive(tld)).to.equal(true);
            }
            expect(await aed.isTldFree("aed")).to.equal(true);
            expect(await aed.getTLDPrice("alsania")).to.equal(ethers.parseEther("1"));
        });
    });

    describe("Domain Registration", function () {
        it("registers a free domain", async function () {
            const { aed, user1 } = await freshFixture();
            await aed.connect(user1).registerDomain("test", "aed", false);
            expect(await aed.isRegistered("test", "aed")).to.equal(true);
            expect(await aed.ownerOf(1)).to.equal(await user1.getAddress());
            const info = await aed.getDomainInfo(1);
            expect(info.profileURI).to.include("data:application/json;base64,");
        });

        it("requires payment for priced TLDs", async function () {
            const { aed, user1 } = await freshFixture();
            const cost = ethers.parseEther("1");
            await aed.connect(user1).registerDomain("sovereign", "alsania", false, { value: cost });
            expect(await aed.ownerOf(1)).to.equal(await user1.getAddress());
        });

        it("enables subdomain feature on mint when requested", async function () {
            const { aed, user1 } = await freshFixture();
            const subdomainCost = ethers.parseEther("2");
            await aed.connect(user1).registerDomain("parent", "aed", true, { value: subdomainCost });
            expect(await aed.isFeatureEnabled(1, "subdomain")).to.equal(true);
        });

        it("prevents duplicate registrations", async function () {
            const { aed, user1, user2 } = await freshFixture();
            await aed.connect(user1).registerDomain("duplicate", "aed", false);
            await expectRevert(
                aed.connect(user2).registerDomain("duplicate", "aed", false),
                "Domain already exists"
            );
        });

        it("validates TLDs and pricing", async function () {
            const { aed, user1 } = await freshFixture();
            await expectRevert(
                aed.connect(user1).registerDomain("test", "invalid", false),
                "Invalid TLD"
            );
            await expectRevert(
                aed.connect(user1).registerDomain("test", "alsania", false, { value: ethers.parseEther("0.1") }),
                "Insufficient payment"
            );
        });
    });

    describe("Subdomains", function () {
        async function registerParent() {
            const ctx = await freshFixture();
            await ctx.aed
                .connect(ctx.user1)
                .registerDomain("parent", "aed", true, { value: ethers.parseEther("2") });
            return ctx;
        }

        it("mints subdomains when feature enabled", async function () {
            const { aed, user1 } = await registerParent();
            await aed.connect(user1).mintSubdomain(1, "child");
            expect(await aed.ownerOf(2)).to.equal(await user1.getAddress());
            expect(await aed.isRegistered("child.parent", "aed")).to.equal(true);
        });

        it("enforces ownership and feature checks", async function () {
            const { aed, user1, user2 } = await registerParent();
            await expectRevert(
                aed.connect(user2).mintSubdomain(1, "hijack"),
                "Not parent domain owner"
            );
            await aed.connect(user1).registerDomain("nosub", "aed", false);
            await expectRevert(
                aed.connect(user1).mintSubdomain(2, "child"),
                "Subdomains not enabled"
            );
        });

        it("escalates fees after free allowance", async function () {
            const { aed, user1 } = await registerParent();
            expect(await aed.calculateSubdomainFee(1)).to.equal(0n);
            await aed.connect(user1).mintSubdomain(1, "free1");
            expect(await aed.calculateSubdomainFee(1)).to.equal(0n);
            await aed.connect(user1).mintSubdomain(1, "firstPaid");
            expect(await aed.calculateSubdomainFee(1)).to.equal(ethers.parseEther("0.1"));
        });
    });

    describe("Metadata & Reverse Records", function () {
        it("allows owners to set profile and image URIs", async function () {
            const { aed, user1 } = await freshFixture();
            await aed.connect(user1).registerDomain("profile", "aed", false);
            const profileURI = "ipfs://profile.json";
            const imageURI = "ipfs://image.png";
            await aed.connect(user1).setProfileURI(1, profileURI);
            await aed.connect(user1).setImageURI(1, imageURI);
            expect(await aed.getProfileURI(1)).to.equal(profileURI);
            expect(await aed.getImageURI(1)).to.equal(imageURI);
            const tokenURI = await aed.tokenURI(1);
            expect(tokenURI).to.include("data:application/json;base64,");
        });

        it("manages reverse resolution records", async function () {
            const { aed, user1, user2 } = await freshFixture();
            await aed.connect(user1).registerDomain("reverse", "aed", false);
            await aed.connect(user1).setReverse("reverse.aed");
            expect(await aed.getReverse(await user1.getAddress())).to.equal("reverse.aed");
            await aed.connect(user1).clearReverse();
            expect(await aed.getReverse(await user1.getAddress())).to.equal("");
            await expectRevert(
                aed.connect(user2).setReverse("reverse.aed"),
                "Not domain owner"
            );
        });
    });

    describe("Enhancements", function () {
        it("enables subdomain feature with payment and prevents duplicates", async function () {
            const { aed, user1 } = await freshFixture();
            await aed.connect(user1).registerDomain("enhance", "aed", false);
            const cost = ethers.parseEther("2");
            await aed.connect(user1).enableSubdomainFeature(1, { value: cost });
            expect(await aed.isFeatureEnabled(1, "subdomain")).to.equal(true);
            await expectRevert(
                aed.connect(user1).enableSubdomainFeature(1, { value: cost }),
                "Feature already enabled"
            );
        });

        it("supports generic feature purchases and BYO upgrades", async function () {
            const { aed, user1 } = await freshFixture();
            await aed.connect(user1).registerDomain("feature", "aed", false);
            const cost = ethers.parseEther("2");
            await aed.connect(user1).purchaseFeature(1, "subdomain", { value: cost });
            expect(await aed.isFeatureEnabled(1, "subdomain")).to.equal(true);
            const byoCost = ethers.parseEther("5");
            const revenueBefore = await aed.getTotalRevenue();
            await aed.connect(user1).upgradeExternalDomain("example.eth", { value: byoCost });
            const revenueAfter = await aed.getTotalRevenue();
            expect((revenueAfter - revenueBefore).toString()).to.equal(byoCost.toString());
        });
    });

    describe("Batch Operations", function () {
        it("registers multiple domains and aggregates cost", async function () {
            const { aed, user1 } = await freshFixture();
            const names = ["alpha", "beta"];
            const tlds = ["aed", "alsania"];
            const flags = [false, false];
            await aed.connect(user1).batchRegisterDomains(names, tlds, flags, { value: ethers.parseEther("1") });
            expect(await aed.ownerOf(1)).to.equal(await user1.getAddress());
            expect(await aed.ownerOf(2)).to.equal(await user1.getAddress());
        });
    });

    describe("Administration", function () {
        it("updates fees, recipients and TLD status", async function () {
            const { aed, owner, user1 } = await freshFixture();
            const feeRole = await aed.FEE_MANAGER_ROLE();
            const tldRole = await aed.TLD_MANAGER_ROLE();
            await aed.connect(owner).grantRole(feeRole, await owner.getAddress());
            await aed.connect(owner).grantRole(tldRole, await owner.getAddress());
            await aed.connect(owner).updateFee("subdomain", ethers.parseEther("3"));
            expect(await aed.getFeaturePrice("subdomain")).to.equal(ethers.parseEther("3"));
            expect(await aed.getFee("subdomain")).to.equal(ethers.parseEther("3"));
            await aed.connect(owner).configureTLD("new", true, ethers.parseEther("2"));
            expect(await aed.isTLDActive("new")).to.equal(true);
            expect(await aed.getTLDPrice("new")).to.equal(ethers.parseEther("2"));
            await aed.connect(owner).updateFeeRecipient(await user1.getAddress());
            expect(await aed.getFeeCollector()).to.equal(await user1.getAddress());
        });

        it("enforces pause controls", async function () {
            const { aed, owner, user1 } = await freshFixture();
            await aed.connect(owner).pause();
            await expectRevert(
                aed.connect(user1).registerDomain("halted", "aed", false),
                "Contract paused"
            );
            await aed.connect(owner).unpause();
            await aed.connect(user1).registerDomain("resumed", "aed", false);
            expect(await aed.ownerOf(1)).to.equal(await user1.getAddress());
        });
    });

    describe("Ownership & Transfers", function () {
        it("updates balances, listings and reverse records on transfer", async function () {
            const { aed, user1, user2 } = await freshFixture();
            await aed.connect(user1).registerDomain("move", "aed", false);
            await aed.connect(user1).setReverse("move.aed");
            await aed.connect(user1).transferFrom(await user1.getAddress(), await user2.getAddress(), 1);
            expect(await aed.ownerOf(1)).to.equal(await user2.getAddress());
            const user1Domains = await aed.getUserDomains(await user1.getAddress());
            const user2Domains = await aed.getUserDomains(await user2.getAddress());
            expect(user1Domains.length).to.equal(0);
            expect(user2Domains.length).to.equal(1);
            expect(await aed.getReverse(await user1.getAddress())).to.equal("");
            expect(await aed.getReverse(await user2.getAddress())).to.equal("move.aed");
        });
    });

    describe("Edge Cases", function () {
        it("normalizes domain names", async function () {
            const { aed, user1 } = await freshFixture();
            await aed.connect(user1).registerDomain("Test", "aed", false);
            expect(await aed.isRegistered("test", "aed")).to.equal(true);
            expect(await aed.getDomainByTokenId(1)).to.equal("test.aed");
        });

        it("refunds excess funds", async function () {
            const { aed, user1, feeCollector, provider } = await freshFixture();
            const overpayment = ethers.parseEther("5");
            const collectorBefore = await provider.getBalance(await feeCollector.getAddress());
            await aed.connect(user1).registerDomain("refund", "aed", false, { value: overpayment });
            const collectorAfter = await provider.getBalance(await feeCollector.getAddress());
            expect(collectorAfter - collectorBefore).to.equal(0n);
            expect(await aed.getTotalRevenue()).to.equal(0n);
            expect(await aed.ownerOf(1)).to.equal(await user1.getAddress());
        });

        it("supports upgrades via UUPS proxy", async function () {
            const ctx = await freshFixture();
            const { aed, owner } = ctx;
            const implArtifact = await hre.artifacts.readArtifact("AEDImplementation");
            const factory = new ethers.ContractFactory(implArtifact.abi, implArtifact.bytecode, owner);
            const newImpl = await factory.deploy();
            await newImpl.waitForDeployment();
            await aed.connect(owner).upgradeTo(await newImpl.getAddress());
            expect(await aed.version()).to.equal("1.0.0");
        });
    });
});
