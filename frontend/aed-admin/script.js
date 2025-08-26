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

// ===== Subdomain Tiered Pricing Logic =====
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

  const display = document.getElementById("multiplierDisplay");
  const dropdown = document.getElementById("multiplierDropdown");
  const options = dropdown.querySelectorAll(".multiplier-option");

  // Set default to x2
  display.value = "x2";
  selectedMultiplier = 2;

  // Show/hide dropdown
  display.addEventListener("click", () => {
    dropdown.style.display = dropdown.style.display === "block" ? "none" : "block";
  });

  // Option click
  options.forEach(option => {
    option.addEventListener("click", () => {
      selectedMultiplier = Number(option.dataset.value);
      display.value = option.textContent;
      dropdown.style.display = "none";
    });
  });

  // Click outside to close dropdown
  document.addEventListener("click", e => {
    if (!e.target.closest(".multiplier-selector")) {
      dropdown.style.display = "none";
    }
  });
});

// ===== Export for Debugging =====
window.AED = {
  connectWallet,
  disconnectWallet,
  updateSubdomainTiered
};
