const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('AED Deployment', function () {
  let aed;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    const AEDImplementation = await ethers.getContractFactory('AEDImplementation');

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
    // Note: getNextTokenId() is not exposed in the Lite version
  });

  it('Should have admin role configured', async function () {
    const adminRole = await aed.ADMIN_ROLE();
    expect(await aed.hasRole(adminRole, owner.address)).to.be.true;
  });

  it('Should have correct TLD configuration', async function () {
    expect(await aed.isTLDActive('aed')).to.be.true;
    expect(await aed.isTLDActive('alsania')).to.be.true;
  });

  it('Supports upgrading to a new implementation', async function () {
    const AEDImplementationV2 = await ethers.getContractFactory('AEDImplementationV2Mock');
    const upgraded = await upgrades.upgradeProxy(aed.getAddress(), AEDImplementationV2);
    expect(await upgraded.version()).to.equal('v2-mock');
  });
});