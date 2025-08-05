const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('AED Contract', function () {
  let aed;
  let owner;
  let user1;
  let feeCollector;

  beforeEach(async function () {
    [owner, user1, feeCollector] = await ethers.getSigners();
    
    const AEDImplementation = await ethers.getContractFactory('AEDImplementation');
    aed = await upgrades.deployProxy(
      AEDImplementation,
      ['Alsania Enhanced Domains', 'AED', feeCollector.address, owner.address],
      { initializer: 'initialize', kind: 'uups' }
    );
    await aed.waitForDeployment();
  });

  it('should deploy successfully', async function () {
    expect(await aed.name()).to.equal('Alsania Enhanced Domains');
    expect(await aed.symbol()).to.equal('AED');
  });

  it('should have correct admin role', async function () {
    const ADMIN_ROLE = await aed.ADMIN_ROLE();
    expect(await aed.hasRole(ADMIN_ROLE, owner.address)).to.be.true;
  });

  it('should allow domain registration', async function () {
    const balanceBefore = await aed.balanceOf(owner.address);
    console.log('Balance before:', balanceBefore.toString());
    
    const tx = await aed.registerDomain('test', 'aed', false);
    const receipt = await tx.wait();
    console.log('Transaction hash:', receipt.hash);
    console.log('Gas used:', receipt.gasUsed.toString());
    
    const balanceAfter = await aed.balanceOf(owner.address);
    console.log('Balance after:', balanceAfter.toString());
    
    // Check if domain was registered
    try {
      const tokenId = 1;
      const owner_address = await aed.ownerOf(tokenId);
      console.log('Owner of token 1:', owner_address);
    } catch (e) {
      console.log('Token 1 does not exist:', e.message);
    }
    
    // Should have minted token ID 1
    expect(balanceAfter).to.equal(1);
  });
});
