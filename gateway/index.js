require("dotenv").config();
const express = require("express");
const { ethers } = require("ethers");
const app = express();

const RPC = process.env.POLYGON_RPC || "http://127.0.0.1:8545";
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const ABI = require("../artifacts/contracts/EnhancedDomain.sol/EnhancedDomain.json").abi;

const provider = new ethers.JsonRpcProvider(RPC);
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);

app.get("/:tokenId/:key", async (req, res) => {
  try {
    const { tokenId, key } = req.params;
    const value = await contract.getRecord(tokenId, key);
    res.json({ value });
  } catch (err) {
    res.status(500).json({ error: err.toString() });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`Gateway running on port ${PORT}`));
