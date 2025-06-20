const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const payees = [deployer.address];
  const shares = [100];  
  const AED = await ethers.getContractFactory("AED");
  const proxy = await upgrades.deployProxy(
    AED,
    [payees, shares],
    {
      initializer: "initialize",
      unsafeAllow: ["delegatecall"]
    }
  );
  await proxy.deployed();
  const implAddr = await upgrades.erc1967.getImplementationAddress(proxy.address);

  console.log("AED proxy deployed to:", proxy.address);
  console.log("AED implementation at:", implAddr);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});