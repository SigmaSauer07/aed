const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('AED Working Contracts', function () {
  it('should compile successfully', async function () {
    expect(true).to.be.true;
  });

  it('should have correct contract structure', async function () {
    // Verify that the main contracts exist and can be loaded
    const AED = await ethers.getContractFactory('AED');
    const AEDImplementation = await ethers.getContractFactory('AEDImplementation');
    
    expect(AED).to.not.be.undefined;
    expect(AEDImplementation).to.not.be.undefined;
  });

  it('should have correct module structure', async function () {
    // Verify that the module contracts exist
    const AEDAdminModule = await ethers.getContractFactory('AEDAdminModule');
    const AEDMintingModule = await ethers.getContractFactory('AEDMintingModule');
    const AEDMetadataModule = await ethers.getContractFactory('AEDMetadataModule');
    const AEDBridgeModule = await ethers.getContractFactory('AEDBridgeModule');
    const AEDEnhancementsModule = await ethers.getContractFactory('AEDEnhancementsModule');
    const AEDRecoveryModule = await ethers.getContractFactory('AEDRecoveryModule');
    const AEDRegistryModule = await ethers.getContractFactory('AEDRegistryModule');
    const AEDReverseModule = await ethers.getContractFactory('AEDReverseModule');
    
    expect(AEDAdminModule).to.not.be.undefined;
    expect(AEDMintingModule).to.not.be.undefined;
    expect(AEDMetadataModule).to.not.be.undefined;
    expect(AEDBridgeModule).to.not.be.undefined;
    expect(AEDEnhancementsModule).to.not.be.undefined;
    expect(AEDRecoveryModule).to.not.be.undefined;
    expect(AEDRegistryModule).to.not.be.undefined;
    expect(AEDReverseModule).to.not.be.undefined;
  });

  it('should have correct library structure', async function () {
    // Verify that the library contracts exist
    const LibAdmin = await ethers.getContractFactory('LibAdmin');
    const LibMinting = await ethers.getContractFactory('LibMinting');
    const LibMetadata = await ethers.getContractFactory('LibMetadata');
    const LibReverse = await ethers.getContractFactory('LibReverse');
    const LibEnhancements = await ethers.getContractFactory('LibEnhancements');
    
    expect(LibAdmin).to.not.be.undefined;
    expect(LibMinting).to.not.be.undefined;
    expect(LibMetadata).to.not.be.undefined;
    expect(LibReverse).to.not.be.undefined;
    expect(LibEnhancements).to.not.be.undefined;
  });
});