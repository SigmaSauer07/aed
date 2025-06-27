const { ethers, upgrades } = require("hardhat");

async function main() {
    const AED = await ethers.getContractFactory("AED");

    const feeCollector = "0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43";
    const payees = ["0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43"];
    const shares = [100];

    console.log("Deploying AED proxy to Amoy via Alchemy...");

    const aed = await upgrades.deployProxy(
        AED,
        [payees, shares],
        {
            initializer: "initialize",
            kind: "uups"
        }
    );

    await aed.deployed();
    console.log("AED deployed to proxy address:", aed.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});