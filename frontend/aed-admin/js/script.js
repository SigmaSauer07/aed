let readContract;
let writeContract;
let signer;
let abi;

const feedback = {
  fee: document.getElementById("feeRecipientFeedback"),
  tld: document.getElementById("tldFeedback"),
  feature: document.getElementById("featureFeedback"),
  role: document.getElementById("roleFeedback"),
  pause: document.getElementById("pauseFeedback"),
};

const config = window.AED_ADMIN_CONFIG;

async function loadAbi() {
  if (abi) return abi;
  const response = await fetch("./js/aedABI.json");
  const json = await response.json();
  abi = json.abi || json;
  return abi;
}

async function getReadContract() {
  if (readContract) return readContract;
  const contractAbi = await loadAbi();
  const provider = new ethers.JsonRpcProvider(config.RPC_URL);
  readContract = new ethers.Contract(config.CONTRACT_ADDRESS, contractAbi, provider);
  return readContract;
}

async function ensureWriteContract() {
  if (writeContract) return writeContract;
  if (!window.ethereum) throw new Error("Wallet not detected");

  const contractAbi = await loadAbi();
  const provider = new ethers.BrowserProvider(window.ethereum, "any");
  await provider.send("eth_requestAccounts", []);
  const network = await provider.getNetwork();
  const desiredChainId = BigInt(config.NETWORK.chainId);
  if (network.chainId !== desiredChainId) {
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: config.NETWORK.chainId }],
    });
  }

  signer = await provider.getSigner();
  writeContract = new ethers.Contract(config.CONTRACT_ADDRESS, contractAbi, signer);
  const address = await signer.getAddress();
  document.getElementById("walletStatus").textContent = `Wallet: ${address.slice(0, 6)}…${address.slice(-4)}`;
  document.getElementById("connectWallet").textContent = "Connected";
  return writeContract;
}

function formatMatic(value) {
  return Number(ethers.formatEther(value)).toFixed(3);
}

async function refreshSnapshot() {
  try {
    const contract = await getReadContract();
    const [totalSupply, totalRevenue, feeCollector, paused] = await Promise.all([
      contract.totalSupply(),
      contract.getTotalRevenue(),
      contract.getFeeCollector(),
      contract.isPaused(),
    ]);

    document.getElementById("contractAddressLabel").textContent = config.CONTRACT_ADDRESS;
    document.getElementById("totalSupply").textContent = totalSupply.toString();
    document.getElementById("totalRevenue").textContent = formatMatic(totalRevenue);
    document.getElementById("feeCollector").textContent = feeCollector;
    document.getElementById("pauseStatus").textContent = paused ? "Yes" : "No";
    document.getElementById("contractAddressLabel").dataset.paused = paused ? "paused" : "active";
  } catch (error) {
    console.error("Snapshot refresh failed", error);
  }
}

function setFeedback(target, message, isError = false) {
  if (!target) return;
  target.textContent = message;
  target.style.color = isError ? "#ff3860" : "#39ff14";
  if (message) {
    setTimeout(() => {
      if (target.textContent === message) {
        target.textContent = "";
      }
    }, 5000);
  }
}

async function submitFeeRecipient(event) {
  event.preventDefault();
  try {
    const contract = await ensureWriteContract();
    const newRecipient = document.getElementById("newFeeRecipient").value.trim();
    const tx = await contract.updateFeeRecipient(newRecipient);
    await tx.wait();
    setFeedback(feedback.fee, "Fee recipient updated");
    refreshSnapshot();
  } catch (error) {
    console.error(error);
    setFeedback(feedback.fee, error.reason || error.message, true);
  }
}

async function submitTld(event) {
  event.preventDefault();
  try {
    const contract = await ensureWriteContract();
    const tld = document.getElementById("tldName").value.trim().toLowerCase();
    const price = document.getElementById("tldPrice").value;
    const isActive = document.getElementById("tldActive").checked;
    const priceWei = ethers.parseEther(price || "0");
    const tx = await contract.configureTLD(tld, isActive, priceWei);
    await tx.wait();
    setFeedback(feedback.tld, `TLD .${tld} ${isActive ? "activated" : "updated"}`);
    refreshSnapshot();
  } catch (error) {
    console.error(error);
    setFeedback(feedback.tld, error.reason || error.message, true);
  }
}

function resolveFeatureKey() {
  const select = document.getElementById("featureKey");
  const customWrapper = document.getElementById("customFeatureWrapper");
  if (select.value === "custom") {
    customWrapper.classList.remove("hidden");
    return document.getElementById("customFeatureName").value.trim();
  }
  customWrapper.classList.add("hidden");
  return select.value;
}

async function submitFeature(event) {
  event.preventDefault();
  try {
    const contract = await ensureWriteContract();
    const featureName = resolveFeatureKey();
    if (!featureName) {
      setFeedback(feedback.feature, "Enter feature name", true);
      return;
    }
    const price = document.getElementById("featurePrice").value;
    const flag = BigInt(document.getElementById("featureFlag").value || "0");
    const priceWei = ethers.parseEther(price || "0");

    if (flag !== 0n) {
      const tx = await contract.addFeature(featureName, priceWei, flag);
      await tx.wait();
    } else {
      const tx = await contract.setFeaturePrice(featureName, priceWei);
      await tx.wait();
    }

    setFeedback(feedback.feature, `Feature ${featureName} updated`);
  } catch (error) {
    console.error(error);
    setFeedback(feedback.feature, error.reason || error.message, true);
  }
}

async function handleRole(action) {
  try {
    const contract = await ensureWriteContract();
    const roleName = document.getElementById("roleSelect").value;
    const account = document.getElementById("roleAccount").value.trim();
    const role = await contract[roleName]();

    if (action === "grant") {
      const tx = await contract.grantRole(role, account);
      await tx.wait();
      setFeedback(feedback.role, `${roleName} granted`);
    } else if (action === "revoke") {
      const tx = await contract.revokeRole(role, account);
      await tx.wait();
      setFeedback(feedback.role, `${roleName} revoked`);
    } else if (action === "check") {
      const hasRole = await contract.hasRole(role, account);
      setFeedback(feedback.role, hasRole ? `${account} holds ${roleName}` : `${account} lacks ${roleName}`);
    }
  } catch (error) {
    console.error(error);
    setFeedback(feedback.role, error.reason || error.message, true);
  }
}

async function handlePause(shouldPause) {
  try {
    const contract = await ensureWriteContract();
    const tx = shouldPause ? await contract.pause() : await contract.unpause();
    await tx.wait();
    setFeedback(feedback.pause, shouldPause ? "Contract paused" : "Contract unpaused");
    refreshSnapshot();
  } catch (error) {
    console.error(error);
    setFeedback(feedback.pause, error.reason || error.message, true);
  }
}

document.getElementById("connectWallet").addEventListener("click", async () => {
  try {
    await ensureWriteContract();
  } catch (error) {
    console.error(error);
    setFeedback(feedback.pause, error.reason || error.message, true);
  }
});

document.getElementById("feeRecipientForm").addEventListener("submit", submitFeeRecipient);
document.getElementById("tldForm").addEventListener("submit", submitTld);
document.getElementById("featureForm").addEventListener("submit", submitFeature);
document.getElementById("grantRole").addEventListener("click", () => handleRole("grant"));
document.getElementById("revokeRole").addEventListener("click", () => handleRole("revoke"));
document.getElementById("checkRole").addEventListener("click", () => handleRole("check"));
document.getElementById("pauseContract").addEventListener("click", () => handlePause(true));
document.getElementById("unpauseContract").addEventListener("click", () => handlePause(false));
document.getElementById("featureKey").addEventListener("change", () => resolveFeatureKey());

document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("contractAddressLabel").textContent = config.CONTRACT_ADDRESS;
  resolveFeatureKey();
  refreshSnapshot();
  setInterval(refreshSnapshot, 20000);
});

if (window.ethereum && typeof window.ethereum.on === "function") {
  window.ethereum.on("accountsChanged", () => {
    writeContract = undefined;
    document.getElementById("connectWallet").textContent = "Connect Wallet";
    document.getElementById("walletStatus").textContent = "Wallet: Not connected";
  });
  window.ethereum.on("chainChanged", () => {
    writeContract = undefined;
    refreshSnapshot();
  });
}
