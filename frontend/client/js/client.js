const CONTRACT_ADDRESS = '0x3Bf795D47f7B32f36cbB1222805b0E0c5EF066f1';
let provider, signer, AED;

async function connectWallet() {
  try {
    provider = new ethers.providers.Web3Provider(window.ethereum, "any");
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    const abi = await fetch('js/aedABI.json').then(r => r.json());
    AED = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);
    const address = await signer.getAddress();
    document.getElementById("wallet").innerText = "Wallet: " + address;
    console.log("✅ Connected:", address);
  } catch (e) {
    console.error("Connection failed:", e);
    alert("❌ Failed to connect wallet.");
  }
}

function updateFee() {
  const enabled = document.getElementById("enhSubdomain").checked;
  const fee = enabled ? 2 : 0;
  document.getElementById("feePreview").innerText = "$" + fee.toFixed(2);
}

async function registerDomain() {
  if (!AED) return alert("❌ Connect your wallet first.");

  const name = document.getElementById("domainName").value.trim();
  const tld = document.getElementById("tld").value;
  const subdomainEnh = document.getElementById("enhSubdomain").checked;

  if (!name || !tld) return alert("❌ Name and TLD are required");

  const duration = ethers.BigNumber.from("3153600000"); // 100 years
  const fee = subdomainEnh ? ethers.utils.parseEther("2") : ethers.constants.Zero;

  console.log("📦 ARGS:", { name, tld, fee: fee.toString(), subdomainEnh, duration: duration.toString() });

  try {
    await AED.callStatic.registerDomain(name, tld, fee, subdomainEnh, duration, { value: fee });
  } catch (err) {
    console.error("⛔ callStatic revert:", err);
    return alert("❌ Revert: " + (err.reason || err.message));
  }

  try {
    const est = await AED.estimateGas.registerDomain(name, tld, fee, subdomainEnh, duration, { value: fee });
    const tx = await AED.registerDomain(name, tld, fee, subdomainEnh, duration, {
      value: fee,
      gasLimit: est.mul(12).div(10) // +20%
    });
    const receipt = await tx.wait();
    alert("✅ Registered! Tx Hash: " + receipt.transactionHash);
    console.log("🔗 Tx Receipt:", receipt);
  } catch (err) {
    console.error("❌ Tx failed:", err);
    alert("❌ Tx failed: " + (err.reason || err.message));
  }
}
