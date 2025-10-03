const CONFIG = window.AED_CONFIG || {};

let provider;
let signer;
let contract;
let abi;

const ROLE_KEYS = {
  ADMIN_ROLE: "ADMIN_ROLE",
  FEE_MANAGER_ROLE: "FEE_MANAGER_ROLE",
  TLD_MANAGER_ROLE: "TLD_MANAGER_ROLE",
};

async function loadABI() {
  if (abi) return abi;
  const response = await fetch("./js/aedABI.json");
  const json = await response.json();
  abi = json.abi || json;
  return abi;
}

async function connectWallet() {
  if (!window.ethereum) {
    alert("MetaMask (or another wallet) is required.");
    return;
  }

  try {
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
    provider = new ethers.BrowserProvider(window.ethereum);
    signer = await provider.getSigner();

    const loadedAbi = await loadABI();
    contract = new ethers.Contract(CONFIG.CONTRACT_ADDRESS, loadedAbi, signer);
    window.contract = contract;
    window.signer = signer;

    const address = accounts[0];
    document.getElementById("walletAddress").textContent = `Connected: ${address.slice(0, 6)}…${address.slice(-4)}`;
    const connectBtn = document.getElementById("connectBtn");
    connectBtn.textContent = "Disconnect";
    connectBtn.onclick = disconnectWallet;

    await refreshOverview();
    await loadFeaturePrices();
  } catch (error) {
    console.error("Failed to connect", error);
    alert(`Connection failed: ${error.message || error}`);
  }
}

function disconnectWallet() {
  provider = undefined;
  signer = undefined;
  contract = undefined;
  window.contract = undefined;
  window.signer = undefined;
  document.getElementById("walletAddress").textContent = "Wallet: Not connected";
  const connectBtn = document.getElementById("connectBtn");
  connectBtn.textContent = "Connect Wallet";
  connectBtn.onclick = connectWallet;
}

async function refreshOverview() {
  if (!contract) return;
  try {
    const [supply, revenue, features] = await Promise.all([
      contract.totalSupply(),
      contract.getTotalRevenue(),
      contract.getAvailableFeatures(),
    ]);

    document.getElementById("totalDomains").textContent = supply.toString();
    document.getElementById("totalRevenue").textContent = Number(ethers.formatEther(revenue)).toFixed(2);

    const activeTlds = ["aed", "alsa", "07", "alsania", "fx", "echo"];
    let activeCount = 0;
    const activeList = [];
    for (const tld of activeTlds) {
      const isActive = await contract.isTLDActive(tld);
      if (isActive) {
        activeCount += 1;
        activeList.push(`.${tld}`);
      }
    }

    document.getElementById("activeTLDs").textContent = activeCount.toString();
    document.getElementById("tldsList").textContent = activeList.join(", ");
    const paused = await contract.isPaused();
    document.getElementById("systemStatus").textContent = paused ? "🔴" : "🟢";

    const list = document.getElementById("currentFees");
    if (list) {
      const feeBase = await contract.getFeeValue("subdomainBase");
      const multiplier = await contract.getFeeValue("subdomainMultiplier");
      const freeMints = await contract.getFeeValue("subdomainFreeMints");
      list.innerHTML = `
        <div>Subdomain Base: ${ethers.formatEther(feeBase)} MATIC</div>
        <div>Multiplier: ${multiplier.toString()}x</div>
        <div>Free Mints: ${freeMints.toString()}</div>
      `;
    }

    const featureList = document.getElementById("featurePriceList");
    if (featureList) {
      featureList.innerHTML = "";
      for (const feature of features) {
        const price = await contract.getFeaturePrice(feature);
        const item = document.createElement("div");
        item.textContent = `${feature} ➜ ${ethers.formatEther(price)} MATIC`;
        featureList.appendChild(item);
      }
    }

    const descriptionPreview = document.getElementById("description-preview");
    if (descriptionPreview) {
      const description = await contract.getGlobalDescription();
      descriptionPreview.textContent = description || "No description set";
    }
  } catch (error) {
    console.error("Failed to refresh overview", error);
  }
}

async function loadFeaturePrices() {
  if (!contract) return;
  const features = await contract.getAvailableFeatures();
  const select = document.getElementById("enhancementSelect");
  if (!select) return;

  select.innerHTML = "";
  for (const feature of features) {
    const option = document.createElement("option");
    option.value = feature;
    option.textContent = feature;
    select.appendChild(option);
  }
}

async function checkContractBalance() {
  const address = document.getElementById("contractAddress").value || CONFIG.CONTRACT_ADDRESS;
  if (!provider) {
    alert("Connect wallet to check balance.");
    return;
  }
  const balance = await provider.getBalance(address);
  document.getElementById("balanceResult").textContent = `${ethers.formatEther(balance)} MATIC`;
}

async function pauseContract() {
  await executeTx(() => contract.pause(), "Contract paused");
}

async function unpauseContract() {
  await executeTx(() => contract.unpause(), "Contract unpaused");
}

async function configureTld() {
  const name = document.getElementById("tldName").value.trim().toLowerCase();
  const fee = document.getElementById("tldPrice").value || "0";
  if (!name) {
    alert("Enter a TLD name.");
    return;
  }

  const priceWei = ethers.parseEther(fee || "0");
  await executeTx(() => contract.configureTLD(name, true, priceWei), "TLD configured");
  await refreshOverview();
}

async function deactivateTld() {
  const name = document.getElementById("tldName").value.trim().toLowerCase();
  if (!name) {
    alert("Enter a TLD name.");
    return;
  }
  await executeTx(() => contract.configureTLD(name, false, 0), "TLD deactivated");
  await refreshOverview();
}

async function updateFeaturePrice() {
  const feature = document.getElementById("enhancementSelect").value;
  const price = document.getElementById("enhancementPrice").value;
  if (!feature) {
    alert("Select a feature.");
    return;
  }
  const priceWei = ethers.parseEther(price || "0");
  await executeTx(() => contract.setFeaturePrice(feature, priceWei), "Feature price updated");
  await refreshOverview();
}

async function updateFeeSetting() {
  const type = document.getElementById("feeType").value;
  const amount = document.getElementById("feeAmount").value || "0";
  let value;
  if (type === "subdomainMultiplier" || type === "subdomainFreeMints") {
    value = BigInt(amount || "0");
  } else {
    value = ethers.parseEther(amount);
  }
  await executeTx(() => contract.updateFee(type, value), "Fee updated");
  await refreshOverview();
}

async function updateFeeRecipient() {
  const address = document.getElementById("recipientAddress").value;
  if (!ethers.isAddress(address)) {
    alert("Enter a valid address.");
    return;
  }
  await executeTx(() => contract.updateFeeRecipient(address), "Fee recipient updated");
  await refreshOverview();
}

async function handleRole(action) {
  const address = document.getElementById("roleAddress").value;
  const roleKey = document.getElementById("roleSelect").value;
  if (!ethers.isAddress(address)) {
    alert("Enter a valid address.");
    return;
  }
  if (!ROLE_KEYS[roleKey]) {
    alert("Select a supported role.");
    return;
  }
  const role = await contract[roleKey]();
  if (action === "grant") {
    await executeTx(() => contract.grantRole(role, address), "Role granted");
  } else if (action === "revoke") {
    await executeTx(() => contract.revokeRole(role, address), "Role revoked");
  } else {
    const hasRole = await contract.hasRole(role, address);
    alert(`${address} ${hasRole ? "has" : "does not have"} ${roleKey}`);
  }
}

async function updateGlobalDescription() {
  const description = document.getElementById("global-desc-input").value.trim();
  await executeTx(() => contract.setGlobalDescription(description), "Global description updated");
  const status = document.getElementById("global-description-status");
  if (status) {
    status.textContent = "Description saved.";
  }
  await refreshOverview();
}

async function executeTx(action, successMessage) {
  if (!contract) {
    alert("Connect wallet first.");
    return;
  }
  try {
    const tx = await action();
    await tx.wait();
    if (successMessage) {
      alert(successMessage);
    }
  } catch (error) {
    console.error("Transaction failed", error);
    alert(`Transaction failed: ${error.reason || error.message || error}`);
  }
}

function hideUnsupportedPanels() {
  ["analytics", "emergency", "whitelistStatus", "platformFeeStatus"].forEach((id) => {
    const el = document.getElementById(id);
    if (el) el.closest(".panel")?.remove();
  });
}

function setupListeners() {
  document.getElementById("connectBtn").onclick = connectWallet;
  document.getElementById("checkBalanceBtn").onclick = checkContractBalance;
  document.getElementById("pauseBtn").onclick = pauseContract;
  document.getElementById("unpauseBtn").onclick = unpauseContract;
  document.getElementById("configureTldBtn").onclick = configureTld;
  document.getElementById("deactivateTldBtn").onclick = deactivateTld;
  document.getElementById("updateEnhancementBtn").onclick = updateFeaturePrice;
  document.getElementById("setFeeBtn").onclick = updateFeeSetting;
  document.getElementById("setRecipientBtn").onclick = updateFeeRecipient;
  document.getElementById("grantRoleBtn").onclick = () => handleRole("grant");
  document.getElementById("revokeRoleBtn").onclick = () => handleRole("revoke");
  document.getElementById("checkRoleBtn").onclick = () => handleRole("check");
  document.getElementById("set-global-description-btn")?.addEventListener("click", updateGlobalDescription);
  document.getElementById("loadTldsBtn").onclick = refreshOverview;
  document.getElementById("loadFeesBtn").onclick = refreshOverview;
}

document.addEventListener("DOMContentLoaded", async () => {
  hideUnsupportedPanels();
  setupListeners();
  await loadABI();
});

window.AED_ADMIN = {
  connectWallet,
  refreshOverview,
};
