// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  const AED = await ethers.getContractFactory("AED");
  const aed = await upgrades.deployProxy(AED, [
    "Alsania Domains", 
    "AED",
    deployer.address, // feeCollector
    deployer.address  // admin
  ]);
  
  await aed.deployed();
  console.log("AED deployed to:", aed.address);
}

main();