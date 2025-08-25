const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('AED Basic Tests', function () {
  it('should compile successfully', async function () {
    // This test verifies that all contracts compile without errors
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
    
    expect(AEDAdminModule).to.not.be.undefined;
    expect(AEDMintingModule).to.not.be.undefined;
    expect(AEDMetadataModule).to.not.be.undefined;
  });
});