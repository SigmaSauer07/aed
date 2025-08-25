const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('AED basic role checks', function () {
  it('deploys and grants admin role to deployer', async function () {
    const [deployer] = await ethers.getSigners();

    const AEDImplementation = await ethers.getContractFactory('AEDImplementation');
    const aed = await upgrades.deployProxy(
      AEDImplementation,
      ['Alsania Enhanced Domains', 'AED', deployer.address, deployer.address],
      { initializer: 'initialize', kind: 'uups' }
    );
    await aed.waitForDeployment();

    const adminRole = await aed.ADMIN_ROLE();
    expect(await aed.hasRole(adminRole, deployer.address)).to.equal(true);
  });
});
