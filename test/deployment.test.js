const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('AED Deployment', function () {
  let aed, aedImplementation;
  let owner, user1, user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy AED Implementation using UUPS upgrades
    const AEDImplementation = await ethers.getContractFactory('AEDImplementation');
    
    // Deploy with UUPS proxy
    aed = await upgrades.deployProxy(
        AEDImplementation,
        ["Alsania Enhanced Domains", "AED", owner.address, owner.address],
        {
            initializer: "initialize",
            kind: "uups"
        }
    );
    
    await aed.waitForDeployment();
  });

  it('Should deploy and initialize correctly', async function () {
    expect(await aed.name()).to.equal('Alsania Enhanced Domains');
    expect(await aed.symbol()).to.equal('AED');
    // Note: getNextTokenId() is tracked via AppStorage helper in production contract
  });

  it('Should have admin role configured', async function () {
    const adminRole = await aed.ADMIN_ROLE();
    expect(await aed.hasRole(adminRole, owner.address)).to.be.true;
  });

  it('Should have correct TLD configuration', async function () {
    expect(await aed.isTLDActive('aed')).to.be.true;
    expect(await aed.isTLDActive('alsania')).to.be.true;
  });
});