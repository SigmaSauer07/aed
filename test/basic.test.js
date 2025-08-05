const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('AED System', function () {
  let aed;
  let owner;
  let user1;
  let user2;
  let feeCollector;

  beforeEach(async function () {
    [owner, user1, user2, feeCollector] = await ethers.getSigners();
    
    const AEDImplementation = await ethers.getContractFactory('AEDImplementation');
    aed = await upgrades.deployProxy(
      AEDImplementation,
      ['Alsania Enhanced Domains', 'AED', feeCollector.address, owner.address],
      { initializer: 'initialize' }
    );
    await aed.waitForDeployment();
  });

  describe('Deployment', function () {
    it('should deploy successfully', async function () {
      expect(await aed.getAddress()).to.not.equal(ethers.ZeroAddress);
    });

    it('should set correct initial values', async function () {
      expect(await aed.name()).to.equal('Alsania Enhanced Domains');
      expect(await aed.symbol()).to.equal('AED');
      expect(await aed.getNextTokenId()).to.equal(1n);
    });

    it('should set admin correctly', async function () {
      expect(await aed.hasRole(await aed.ADMIN_ROLE(), owner.address)).to.be.true;
    });
  });

  describe('Domain Registration', function () {
    it('should register a free domain', async function () {
      await aed.connect(user1).registerDomain('test', 'aed', false, { value: 0 });
      
      expect(await aed.isRegistered('test', 'aed')).to.be.true;
      expect(await aed.getDomainOwner('test.aed')).to.equal(user1.address);
    });

    it('should register a paid domain', async function () {
      const price = ethers.parseEther('1');
      await aed.connect(user1).registerDomain('test', 'alsania', false, { value: price });
      
      expect(await aed.isRegistered('test', 'alsania')).to.be.true;
    });

    it('should fail with insufficient payment', async function () {
      const price = ethers.parseEther('1');
      await expect(
        aed.connect(user1).registerDomain('test', 'alsania', false, { value: price - 1n })
      ).to.be.revertedWith('Insufficient payment');
    });

    it('should fail for duplicate domain', async function () {
      await aed.connect(user1).registerDomain('test', 'aed', false, { value: 0 });
      await expect(
        aed.connect(user2).registerDomain('test', 'aed', false, { value: 0 })
      ).to.be.revertedWith('Domain already exists');
    });
  });

  describe('Subdomain Creation', function () {
    beforeEach(async function () {
      await aed.connect(user1).registerDomain('parent', 'aed', true, { value: ethers.parseEther('2') });
    });

    it('should create subdomain', async function () {
      await aed.connect(user2).mintSubdomain(1, 'child', { value: 0 });
      
      expect(await aed.isRegistered('child', 'parent.aed')).to.be.true;
    });

    it('should fail without subdomain enhancement', async function () {
      await aed.connect(user1).registerDomain('parent2', 'aed', false, { value: 0 });
      await expect(
        aed.connect(user2).mintSubdomain(2, 'child', { value: 0 })
      ).to.be.revertedWith('Subdomains not enabled');
    });
  });

  describe('Metadata', function () {
    beforeEach(async function () {
      await aed.connect(user1).registerDomain('test', 'aed', false, { value: 0 });
    });

    it('should set profile URI', async function () {
      await aed.connect(user1).setProfileURI(1, 'ipfs://profile');
      expect(await aed.getProfileURI(1)).to.equal('ipfs://profile');
    });

    it('should set image URI', async function () {
      await aed.connect(user1).setImageURI(1, 'ipfs://image');
      expect(await aed.getImageURI(1)).to.equal('ipfs://image');
    });

    it('should generate token URI', async function () {
      const tokenURI = await aed.tokenURI(1);
      expect(tokenURI).to.include('data:application/json;base64,');
    });
  });

  describe('Reverse Resolution', function () {
    beforeEach(async function () {
      await aed.connect(user1).registerDomain('test', 'aed', false, { value: 0 });
    });

    it('should set reverse record', async function () {
      await aed.connect(user1).setReverse('test.aed');
      expect(await aed.getReverse(user1.address)).to.equal('test.aed');
    });

    it('should clear reverse record', async function () {
      await aed.connect(user1).setReverse('test.aed');
      await aed.connect(user1).clearReverse();
      expect(await aed.getReverse(user1.address)).to.equal('');
    });
  });

  describe('Admin Functions', function () {
    it('should update fee', async function () {
      await aed.connect(owner).updateFee('test', ethers.parseEther('5'));
      expect(await aed.getFee('test')).to.equal(ethers.parseEther('5'));
    });

    it('should configure TLD', async function () {
      await aed.connect(owner).configureTLD('newtld', true, ethers.parseEther('3'));
      expect(await aed.isTLDActive('newtld')).to.be.true;
    });

    it('should pause and unpause', async function () {
      await aed.connect(owner).pause();
      await expect(
        aed.connect(user1).registerDomain('test', 'aed', false, { value: 0 })
      ).to.be.revertedWith('Contract paused');
      
      await aed.connect(owner).unpause();
      await aed.connect(user1).registerDomain('test', 'aed', false, { value: 0 });
      expect(await aed.isRegistered('test', 'aed')).to.be.true;
    });
  });
});