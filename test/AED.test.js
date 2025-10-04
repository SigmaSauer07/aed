const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("AED - Alsania Enhanced Domains", function () {
    let aed, aedImplementation;
    let owner, user1, user2, feeCollector;
    let ADMIN_ROLE, FEE_MANAGER_ROLE, TLD_MANAGER_ROLE;

    before(async function () {
        [owner, user1, user2, feeCollector] = await ethers.getSigners();
    });

    beforeEach(async function () {
        // Deploy the AED implementation
        const AEDImplementation = await ethers.getContractFactory("AEDImplementationLite");
        
        // Deploy with UUPS proxy
        aed = await upgrades.deployProxy(
            AEDImplementation,
            ["Alsania Enhanced Domains", "AED", feeCollector.address, owner.address],
            {
                initializer: "initialize",
                kind: "uups"
            }
        );
        
        await aed.waitForDeployment();

        // Get role constants
        ADMIN_ROLE = await aed.ADMIN_ROLE();
        FEE_MANAGER_ROLE = await aed.FEE_MANAGER_ROLE();
        TLD_MANAGER_ROLE = await aed.TLD_MANAGER_ROLE();
    });

    describe("Deployment & Initialization", function () {
        it("Should deploy and initialize correctly", async function () {
            expect(await aed.name()).to.equal("Alsania Enhanced Domains");
            expect(await aed.symbol()).to.equal("AED");
        });

        it("Should have admin role configured", async function () {
            expect(await aed.hasRole(ADMIN_ROLE, owner.address)).to.be.true;
        });

        it("Should have correct fee collector", async function () {
            // We'll need to add a getter for fee collector in the implementation
            expect(await aed.getFeeCollector()).to.equal(feeCollector.address);
        });

        it("Should have valid TLDs configured", async function () {
            expect(await aed.isTLDActive("aed")).to.be.true;
            expect(await aed.isTLDActive("alsa")).to.be.true;
            expect(await aed.isTLDActive("07")).to.be.true;
            expect(await aed.isTLDActive("alsania")).to.be.true;
            expect(await aed.isTLDActive("fx")).to.be.true;
            expect(await aed.isTLDActive("echo")).to.be.true;
        });
    });

    describe("Domain Registration", function () {
        it("Should register free domain", async function () {
            const tx = await aed.connect(user1).registerDomain("test", "aed", false);
            const receipt = await tx.wait();

            expect(await aed.isRegistered("test", "aed")).to.be.true;
            expect(await aed.ownerOf(1)).to.equal(user1.address);
            expect(await aed.getDomainByTokenId(1)).to.equal("test.aed");
        });

        it("Should register paid domain", async function () {
            const cost = ethers.parseEther("1"); // $1 for .alsania
            const tx = await aed.connect(user1).registerDomain("test", "alsania", false, { value: cost });
            const receipt = await tx.wait();
            
            expect(await aed.isRegistered("test", "alsania")).to.be.true;
            expect(await aed.ownerOf(1)).to.equal(user1.address);
        });

        it("Should register domain with subdomain feature", async function () {
            const subdomainCost = ethers.parseEther("2"); // $2 for subdomain enhancement
            const tx = await aed.connect(user1).registerDomain("test", "aed", true, { value: subdomainCost });
            const receipt = await tx.wait();
            
            expect(await aed.isFeatureEnabled(1, "subdomain")).to.be.true;
        });

        it("Should fail to register existing domain", async function () {
            await aed.connect(user1).registerDomain("test", "aed", false);
            
            await expect(
                aed.connect(user2).registerDomain("test", "aed", false)
            ).to.be.revertedWith("Domain already exists");
        });

        it("Should fail with invalid TLD", async function () {
            await expect(
                aed.connect(user1).registerDomain("test", "invalid", false)
            ).to.be.revertedWith("Invalid TLD");
        });

        it("Should fail with insufficient payment", async function () {
            const insufficientAmount = ethers.parseEther("0.5");
            await expect(
                aed.connect(user1).registerDomain("test", "alsania", false, { value: insufficientAmount })
            ).to.be.revertedWith("Insufficient payment");
        });
    });

    describe("Subdomain Creation", function () {
        beforeEach(async function () {
            // Register a domain with subdomain feature
            const cost = ethers.parseEther("2");
            await aed.connect(user1).registerDomain("parent", "aed", true, { value: cost });
        });

        it("Should create subdomain", async function () {
            const tx = await aed.connect(user1).mintSubdomain(1, "child");
            const receipt = await tx.wait();
            
            expect(await aed.isRegistered("child.parent", "aed")).to.be.true;
            expect(await aed.ownerOf(2)).to.equal(user1.address);
        });

        it("Should calculate correct subdomain fees", async function () {
            // First 2 subdomains are free
            expect(await aed.calculateSubdomainFee(1)).to.equal(0);
            
            await aed.connect(user1).mintSubdomain(1, "child1");
            expect(await aed.calculateSubdomainFee(1)).to.equal(0);
            
            await aed.connect(user1).mintSubdomain(1, "child2");
            expect(await aed.calculateSubdomainFee(1)).to.equal(ethers.parseEther("0.1"));
        });

        it("Should fail to create subdomain without permission", async function () {
            await expect(
                aed.connect(user2).mintSubdomain(1, "child")
            ).to.be.revertedWith("Not parent domain owner");
        });

        it("Should fail to create subdomain on domain without feature", async function () {
            // Register domain without subdomain feature
            await aed.connect(user2).registerDomain("nosubdomains", "aed", false);
            
            await expect(
                aed.connect(user2).mintSubdomain(2, "child")
            ).to.be.revertedWith("Subdomains not enabled");
        });
    });

    describe("Metadata Management", function () {
        beforeEach(async function () {
            await aed.connect(user1).registerDomain("test", "aed", false);
        });

        it("Should seed default metadata endpoints on mint", async function () {
            const expectedProfile = "https://api.alsania.io/metadata/test.aed/profile.json";
            const expectedImage = "https://api.alsania.io/metadata/test.aed/image.png";

            expect(await aed.getProfileURI(1)).to.equal(expectedProfile);
            expect(await aed.getImageURI(1)).to.equal(expectedImage);
        });

        it("Should set profile URI", async function () {
            const profileURI = "https://example.com/profile.json";
            await aed.connect(user1).setProfileURI(1, profileURI);

            expect(await aed.getProfileURI(1)).to.equal(profileURI);
        });

        it("Should set image URI", async function () {
            const imageURI = "https://example.com/image.png";
            await aed.connect(user1).setImageURI(1, imageURI);
            
            expect(await aed.getImageURI(1)).to.equal(imageURI);
        });

        it("Should generate token URI", async function () {
            const tokenURI = await aed.tokenURI(1);
            expect(tokenURI).to.include("data:application/json;base64,");
        });

        it("Should fail to set metadata for non-owned token", async function () {
            await expect(
                aed.connect(user2).setProfileURI(1, "https://example.com")
            ).to.be.revertedWith("Not token owner");
        });

        it("Should assign defaults for subdomains", async function () {
            await aed.connect(user1).registerDomain("parent", "aed", true, {
                value: ethers.parseEther("2"),
            });
            await aed.connect(user1).mintSubdomain(2, "child");

            const expectedProfile = "https://api.alsania.io/metadata/child.parent.aed/profile.json";
            expect(await aed.getProfileURI(3)).to.equal(expectedProfile);
        });
    });

    describe("Reverse Resolution", function () {
        beforeEach(async function () {
            await aed.connect(user1).registerDomain("test", "aed", false);
            await aed.connect(user1).registerDomain("test2", "alsania", false, { value: ethers.parseEther("1") });
        });

        it("Should set reverse record", async function () {
            await aed.connect(user1).setReverse("test.aed");
            
            expect(await aed.getReverse(user1.address)).to.equal("test.aed");
            expect(await aed.getReverseOwner("test.aed")).to.equal(user1.address);
        });

        it("Should clear reverse record", async function () {
            await aed.connect(user1).setReverse("test.aed");
            await aed.connect(user1).clearReverse();
            
            expect(await aed.getReverse(user1.address)).to.equal("");
        });

        it("Should fail to set reverse for non-owned domain", async function () {
            await expect(
                aed.connect(user2).setReverse("test.aed")
            ).to.be.revertedWith("Not domain owner");
        });
    });

    describe("Feature Enhancement", function () {
        beforeEach(async function () {
            await aed.connect(user1).registerDomain("test", "aed", false);
        });

        it("Should enable subdomain feature", async function () {
            const cost = ethers.parseEther("2");
            await aed.connect(user1).enableSubdomainFeature(1, { value: cost });
            
            expect(await aed.isFeatureEnabled(1, "subdomain")).to.be.true;
        });

        it("Should purchase feature", async function () {
            const cost = ethers.parseEther("2");
            await aed.connect(user1).purchaseFeature(1, "subdomain", { value: cost });
            
            expect(await aed.isFeatureEnabled(1, "subdomain")).to.be.true;
        });

        it("Should upgrade external domain", async function () {
            const cost = ethers.parseEther("5");
            const tx = await aed.connect(user1).upgradeExternalDomain("example.eth", { value: cost });
            const receipt = await tx.wait();
            
            // Should complete without reverting
            expect(receipt.status).to.equal(1);
        });

        it("Should fail with insufficient payment", async function () {
            const insufficientAmount = ethers.parseEther("1");
            await expect(
                aed.connect(user1).enableSubdomainFeature(1, { value: insufficientAmount })
            ).to.be.revertedWith("Insufficient payment");
        });
    });

    describe("Batch Operations", function () {
        it("Should batch register multiple domains", async function () {
            const names = ["test1", "test2", "test3"];
            const tlds = ["aed", "alsa", "07"];
            const enableSubdomains = [false, false, false];
            
            const tokenIds = await aed.connect(user1).batchRegisterDomains(names, tlds, enableSubdomains);
            
            expect(await aed.ownerOf(1)).to.equal(user1.address);
            expect(await aed.ownerOf(2)).to.equal(user1.address);
            expect(await aed.ownerOf(3)).to.equal(user1.address);
        });

        it("Should batch register with mixed free and paid domains", async function () {
            const names = ["free", "paid"];
            const tlds = ["aed", "alsania"];
            const enableSubdomains = [false, false];
            const cost = ethers.parseEther("1"); // Cost for .alsania
            
            await aed.connect(user1).batchRegisterDomains(names, tlds, enableSubdomains, { value: cost });
            
            expect(await aed.ownerOf(1)).to.equal(user1.address);
            expect(await aed.ownerOf(2)).to.equal(user1.address);
        });
    });

    describe("Admin Functions", function () {
        it("Should update fee", async function () {
            await aed.connect(owner).grantRole(FEE_MANAGER_ROLE, owner.address);
            await aed.connect(owner).updateFee("subdomain", ethers.parseEther("3"));
            
            expect(await aed.getFeaturePrice("subdomain")).to.equal(ethers.parseEther("3"));
        });

        it("Should configure TLD", async function () {
            await aed.connect(owner).grantRole(TLD_MANAGER_ROLE, owner.address);
            await aed.connect(owner).configureTLD("newtld", true, ethers.parseEther("2"));
            
            expect(await aed.isTLDActive("newtld")).to.be.true;
        });

        it("Should update fee recipient", async function () {
            const newRecipient = user1.address;
            await aed.connect(owner).updateFeeRecipient(newRecipient);
            
            expect(await aed.getFeeCollector()).to.equal(newRecipient);
        });

        it("Should pause and unpause contract", async function () {
            await aed.connect(owner).pause();
            
            await expect(
                aed.connect(user1).registerDomain("test", "aed", false)
            ).to.be.revertedWith("Contract paused");
            
            await aed.connect(owner).unpause();
            
            // Should work again after unpause
            await aed.connect(user1).registerDomain("test", "aed", false);
            expect(await aed.ownerOf(1)).to.equal(user1.address);
        });

        it("Should fail admin functions without proper role", async function () {
            await expect(
                aed.connect(user1).updateFee("subdomain", ethers.parseEther("3"))
            ).to.be.revertedWith("Not fee manager");

            await expect(
                aed.connect(user1).configureTLD("newtld", true, ethers.parseEther("2"))
            ).to.be.revertedWith("Not TLD manager");

            await expect(
                aed.connect(user1).pause()
            ).to.be.revertedWith("Not admin");
        });
    });

    describe("Transfer & Ownership", function () {
        beforeEach(async function () {
            await aed.connect(user1).registerDomain("test", "aed", false);
        });

        it("Should transfer domain", async function () {
            await aed.connect(user1).transferFrom(user1.address, user2.address, 1);
            
            expect(await aed.ownerOf(1)).to.equal(user2.address);
        });

        it("Should update user domain arrays on transfer", async function () {
            const user1DomainsBefore = await aed.getUserDomains(user1.address);
            const user2DomainsBefore = await aed.getUserDomains(user2.address);
            
            await aed.connect(user1).transferFrom(user1.address, user2.address, 1);
            
            const user1DomainsAfter = await aed.getUserDomains(user1.address);
            const user2DomainsAfter = await aed.getUserDomains(user2.address);
            
            expect(user1DomainsAfter.length).to.equal(user1DomainsBefore.length - 1);
            expect(user2DomainsAfter.length).to.equal(user2DomainsBefore.length + 1);
        });

        it("Should handle reverse resolution on transfer", async function () {
            await aed.connect(user1).setReverse("test.aed");
            await aed.connect(user1).transferFrom(user1.address, user2.address, 1);
            
            // Old owner should lose reverse record
            expect(await aed.getReverse(user1.address)).to.equal("");
            // New owner should automatically get reverse record if they have none
            expect(await aed.getReverse(user2.address)).to.equal("test.aed");
        });
    });

    describe("Edge Cases & Security", function () {
        it("Should handle domain name normalization", async function () {
            await aed.connect(user1).registerDomain("Test", "aed", false);
            
            expect(await aed.isRegistered("test", "aed")).to.be.true;
            expect(await aed.getDomainByTokenId(1)).to.equal("test.aed");
        });

        it("Should handle maximum subdomain limits", async function () {
            const cost = ethers.parseEther("2");
            await aed.connect(user1).registerDomain("parent", "aed", true, { value: cost });
            
            // This test would need to be adjusted based on MAX_SUBDOMAINS constant
            // For now, we'll just verify it doesn't fail for a few subdomains
            await aed.connect(user1).mintSubdomain(1, "child1");
            await aed.connect(user1).mintSubdomain(1, "child2");
        });

        it("Should handle fee refunds", async function () {
            const overpayment = ethers.parseEther("5");
            const balanceBefore = await ethers.provider.getBalance(user1.address);
            
            const tx = await aed.connect(user1).registerDomain("test", "aed", false, { value: overpayment });
            const receipt = await tx.wait();
            const gasUsed = receipt.gasUsed * receipt.gasPrice;
            
            const balanceAfter = await ethers.provider.getBalance(user1.address);
            
            // Should only charge for gas, overpayment should be refunded
            expect(balanceBefore - balanceAfter).to.be.closeTo(gasUsed, ethers.parseEther("0.01"));
        });
    });
});
