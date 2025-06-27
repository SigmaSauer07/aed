const CONTRACT_ADDRESS = '0x3Bf795D47f7B32f36cbB1222805b0E0c5EF066f1';
let provider, signer, AED;

async function connectWallet() {
  try {
    provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    const abi = await fetch('js/aedABI.json').then(r => r.json());
    AED = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);
    const address = await signer.getAddress();
    document.getElementById("wallet").innerText = "Wallet: " + address;
    console.log("✅ Connected:", address);
  } catch (e) {
    console.error("Connection failed:", e);
  }
}

function updateFee() {
  const fee = document.getElementById("enhSubdomain").checked ? 2 : 0;
  document.getElementById("feePreview").innerText = "$" + fee.toFixed(2);
}

async function registerDomain() {
  if (!AED) return alert("Connect wallet first.");
  const name = document.getElementById("domainName").value;
  const tld = document.getElementById("tld").value;
  const { ethers } = window;

  const duration = 3153600000;
  const price = await AED.renewalPrice();
  const tx = await AED.registerDomain(name, tld, 0, false, duration, {
    value: price.mul(duration)
  });
  const receipt = await tx.wait();

  const event = receipt.events.find(e => e.event === "DomainRegistered");
  const tokenId = event?.args?.tokenId;

  if (document.getElementById("enhSubdomain").checked && tokenId) {
    const fee = ethers.utils.parseEther("2.0").div(1000);
    const enhanceTx = await AED.purchaseFeature(tokenId, 0x04, { value: fee });
    await enhanceTx.wait();
  }

  alert("✅ Domain registered!");
}
