// ===== Configuration =====
const CONTRACT_ADDRESS = '0x3Bf795D47f7B32f36cbB1222805b0E0c5EF066f1';
const AED_ABI = [ /* << Paste your full ABI here >> */ ];

let provider, signer, contract, selectedMultiplier = 2;

// ===== Wallet Connect / Disconnect =====
async function connectWallet() {
  if (!window.ethereum) return alert("Install MetaMask!");
  provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = provider.getSigner();
  contract = new ethers.Contract(CONTRACT_ADDRESS, AED_ABI, signer);
  const addr = await signer.getAddress();

  document.getElementById("walletStatus").innerText = `Connected: ${addr.slice(0,6)}...${addr.slice(-4)}`;
  const btn = document.getElementById("connectBtn");
  btn.textContent = "Disconnect";
  btn.onclick = disconnectWallet;
}

function disconnectWallet() {
  provider = signer = contract = null;
  document.getElementById("walletStatus").innerText = "Wallet: Not connected";
  const btn = document.getElementById("connectBtn");
  btn.textContent = "Connect Wallet";
  btn.onclick = connectWallet;
}

// ===== Multiplier Selector =====
function createMultiplierButtons() {
  const container = document.getElementById("multiplierButtons");
  for (let i = 0; i <= 10; i++) {
    const btn = document.createElement("button");
    btn.textContent = `x${i}`;
    btn.value = i;
    if (i === selectedMultiplier) btn.classList.add("selected");
    btn.onclick = () => {
      selectedMultiplier = i;
      container.querySelectorAll("button").forEach(b => b.classList.remove("selected"));
      btn.classList.add("selected");
    };
    container.appendChild(btn);
  }
}

async function updateSubdomainTiered() {
  const base = document.getElementById("subdomainBaseFee").value;
  const status = document.getElementById("subdomainTieredStatus");
  status.innerText = `⏱️ Updating: base=${base}, x${selectedMultiplier}…`;
  // contract logic can go here
  status.innerText = `✅ Tiered pricing set: ${base} × ${selectedMultiplier}`;
}

// ===== Initialization =====
document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("connectBtn").onclick = connectWallet;
  document.getElementById("updateSubdomainTieredBtn").onclick = updateSubdomainTiered;
  createMultiplierButtons();
  // Add other panel handlers here (grantRoleBtn, updateTldPriceBtn etc.)
});

// ===== Testing =====
window.AED = { connectWallet, disconnectWallet, updateSubdomainTiered };