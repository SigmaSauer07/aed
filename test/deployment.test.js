const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('AED Deployment', function () {
  let aed, aedImplementation;
  let owner, user1, user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    const AEDImplementation = await ethers.getContractFactory('AEDImplementation');
    const { upgrades } = require('hardhat');
    aed = await upgrades.deployProxy(
      AEDImplementation,
      ['Alsania Enhanced Domains', 'AED', owner.address, owner.address],
      { initializer: 'initialize', kind: 'uups' }
    );
    await aed.waitForDeployment();
  });

  it('Should deploy and initialize correctly', async function () {
    expect(await aed.name()).to.equal('Alsania Enhanced Domains');
    expect(await aed.symbol()).to.equal('AED');
    expect(await aed.getNextTokenId()).to.equal(1);
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