const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('AED Deployment', function () {
  let aed, aedImplementation;
  let owner, user1, user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy only the required library for AEDImplementation
    const LibMinting = await ethers.getContractFactory('LibMinting');
    const libMinting = await LibMinting.deploy();
    await libMinting.waitForDeployment();

    // Deploy implementation with library link
    const AEDImplementation = await ethers.getContractFactory('AEDImplementation', {
      libraries: {
        'contracts/libraries/LibMinting.sol:LibMinting': await libMinting.getAddress()
      }
    });
    aedImplementation = await AEDImplementation.deploy();
    await aedImplementation.waitForDeployment();

    // Deploy proxy
    const AED = await ethers.getContractFactory('AED');
    const initData = aedImplementation.interface.encodeFunctionData(
      'initialize',
      ['Alsania Enhanced Domains', 'AED', owner.address, owner.address]
    );

    aed = await AED.deploy(await aedImplementation.getAddress(), initData);
    await aed.waitForDeployment();

    // Connect to proxy with implementation interface
    aed = aedImplementation.attach(await aed.getAddress());
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