const { run } = require("hardhat");
require("dotenv").config();

async function main() {
  const proxy = "<PROXY_ADDRESS>";
  const impl = "<IMPLEMENTATION_ADDRESS>"; // You can extract this via block explorer

  await run("verify:verify", {
    address: impl,
    constructorArguments: [],
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
