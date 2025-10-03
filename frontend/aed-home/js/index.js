const CONFIG = window.AED_CONFIG || {};

let provider;
let signer;
let AED;
let ABI;

const ALSANIA_TLDS = ["aed", "alsa", "07", "alsania", "fx", "echo"];

async function loadABI() {
  if (ABI) {
    return ABI;
  }

  const response = await fetch("./js/aedABI.json");
  const abiJson = await response.json();
  ABI = abiJson.abi || abiJson;
  return ABI;
}

function formatMatic(amountWei) {
  try {
    return `${Number(ethers.formatEther(amountWei)).toFixed(2)} MATIC`;
  } catch (err) {
    return "0.00 MATIC";
  }
}

async function ensureNetwork() {
  if (!CONFIG.NETWORK || !window.ethereum) {
    return;
  }

  const targetChainId = CONFIG.NETWORK.chainId || "0x13882"; // Polygon Amoy default
  const currentChain = await window.ethereum.request({ method: "eth_chainId" });
  if (currentChain !== targetChainId) {
    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: targetChainId }],
      });
    } catch (switchError) {
      if (switchError.code === 4902 && CONFIG.NETWORK.rpcUrls) {
        await window.ethereum.request({
          method: "wallet_addEthereumChain",
          params: [CONFIG.NETWORK],
        });
      } else {
        throw switchError;
      }
    }
  }
}

async function connectWallet() {
  if (!window.ethereum) {
    alert("Please install a Web3 wallet such as MetaMask.");
    return;
  }

  try {
    await ensureNetwork();
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
    provider = new ethers.BrowserProvider(window.ethereum);
    signer = await provider.getSigner();

    const abi = await loadABI();
    AED = new ethers.Contract(CONFIG.CONTRACT_ADDRESS, abi, signer);

    const address = accounts[0];
    const walletLabel = document.getElementById("wallet");
    if (walletLabel) {
      walletLabel.textContent = `Wallet: ${address.slice(0, 6)}…${address.slice(-4)}`;
    }

    const connectBtn = document.getElementById("connectBtn");
    if (connectBtn) {
      connectBtn.textContent = "Connected";
      connectBtn.classList.add("connected");
    }

    updateRegisterTotal();
    updateEnhanceTotal();
  } catch (error) {
    console.error("Wallet connection failed", error);
    alert(`Unable to connect wallet: ${error.message || error}`);
  }
}

function getSelectedTld() {
  const freeTld = document.getElementById("freeTld");
  const featuredTld = document.getElementById("featuredTld");
  return (freeTld?.value || "") || (featuredTld?.value || "");
}

async function updateRegisterTotal() {
  const totalLabel = document.getElementById("registerTotal");
  if (!totalLabel) return;

  const selectedTld = getSelectedTld();
  const subEnh = document.getElementById("enhSubdomain")?.checked || false;

  if (!AED || !selectedTld) {
    totalLabel.textContent = subEnh ? "2.00 MATIC" : "0.00 MATIC";
    return;
  }

  try {
    const total = await AED.estimateDomainPrice(selectedTld, subEnh);
    totalLabel.textContent = formatMatic(total);
  } catch (error) {
    console.warn("Failed to estimate price", error);
    totalLabel.textContent = subEnh ? "2.00 MATIC" : "0.00 MATIC";
  }
}

async function updateEnhanceTotal() {
  const totalLabel = document.getElementById("enhanceTotal");
  if (!totalLabel) return;

  const enhancementChecked = document.getElementById("enhanceSubdomain")?.checked;
  const rawDomain = document.getElementById("existingDomain")?.value.trim();

  if (!enhancementChecked || !rawDomain) {
    totalLabel.textContent = "0.00 MATIC";
    return;
  }

  try {
    const normalized = rawDomain.toLowerCase();
    if (AED) {
      try {
        await AED.getTokenIdByDomain(normalized);
        const price = await AED.getFeaturePrice("subdomain");
        totalLabel.textContent = formatMatic(price);
        return;
      } catch (lookupErr) {
        // Domain not registered, fall back to external upgrade price
      }

      const externalPrice = await AED.getFeaturePrice("byo");
      totalLabel.textContent = formatMatic(externalPrice);
      return;
    }
  } catch (error) {
    console.warn("Unable to load enhancement pricing", error);
  }

  const fallback = ALSANIA_TLDS.some((tld) => rawDomain.toLowerCase().endsWith(`.${tld}`)) ? 2 : 5;
  totalLabel.textContent = `${fallback.toFixed(2)} MATIC`;
}

async function registerDomain() {
  if (!AED) {
    alert("Connect your wallet before registering.");
    return;
  }

  const nameInput = document.getElementById("domainName");
  const name = (nameInput?.value || "").trim();
  const selectedTld = getSelectedTld();
  const withSubdomains = document.getElementById("enhSubdomain")?.checked || false;

  if (!name || !selectedTld) {
    alert("Please enter a domain name and select a TLD.");
    return;
  }

  try {
    const totalCost = await AED.estimateDomainPrice(selectedTld, withSubdomains);
    const tx = await AED.registerDomain(name, selectedTld, withSubdomains, { value: totalCost });
    const receipt = await tx.wait();

    alert(`Domain registered! Tx: ${receipt.hash}`);
    if (nameInput) nameInput.value = "";
    document.getElementById("freeTld").value = "";
    document.getElementById("featuredTld").value = "";
    document.getElementById("enhSubdomain").checked = false;
    updateRegisterTotal();
  } catch (error) {
    console.error("Registration failed", error);
    alert(`Registration failed: ${error.reason || error.message || error}`);
  }
}

async function enhanceDomain() {
  if (!AED) {
    alert("Connect your wallet before enhancing a domain.");
    return;
  }

  const domainField = document.getElementById("existingDomain");
  const enhance = document.getElementById("enhanceSubdomain")?.checked;
  const input = (domainField?.value || "").trim();

  if (!input) {
    alert("Enter a domain name or token ID.");
    return;
  }
  if (!enhance) {
    alert("Select an enhancement to continue.");
    return;
  }

  try {
    let tokenId;
    if (/^\d+$/.test(input)) {
      tokenId = BigInt(input);
    } else {
      const normalized = input.toLowerCase();
      tokenId = await AED.getTokenIdByDomain(normalized);
    }

    const price = await AED.getFeaturePrice("subdomain");
    const tx = await AED.purchaseFeature(tokenId, "subdomain", { value: price });
    const receipt = await tx.wait();

    alert(`Enhancement complete! Tx: ${receipt.hash}`);
    domainField.value = "";
    document.getElementById("enhanceSubdomain").checked = false;
    updateEnhanceTotal();
  } catch (error) {
    console.error("Enhancement failed", error);
    if (error?.message?.includes("Domain not found")) {
      await upgradeExternal(input);
      return;
    }
    alert(`Enhancement failed: ${error.reason || error.message || error}`);
  }
}

async function upgradeExternal(domainName) {
  try {
    const price = await AED.getFeaturePrice("byo");
    const tx = await AED.upgradeExternalDomain(domainName, { value: price });
    const receipt = await tx.wait();
    alert(`External domain upgraded! Tx: ${receipt.hash}`);
  } catch (error) {
    console.error("External upgrade failed", error);
    alert(`Upgrade failed: ${error.reason || error.message || error}`);
  }
}

function setupEventListeners() {
  document.getElementById("connectBtn")?.addEventListener("click", connectWallet);
  document.getElementById("registerBtn")?.addEventListener("click", registerDomain);
  document.getElementById("enhanceBtn")?.addEventListener("click", enhanceDomain);

  ["freeTld", "featuredTld"].forEach((id) => {
    const select = document.getElementById(id);
    if (select) {
      select.addEventListener("change", () => {
        if (id === "freeTld") {
          const featured = document.getElementById("featuredTld");
          if (featured) featured.value = "";
        } else {
          const free = document.getElementById("freeTld");
          if (free) free.value = "";
        }
        updateRegisterTotal();
      });
    }
  });

  document.getElementById("enhSubdomain")?.addEventListener("change", updateRegisterTotal);
  document.getElementById("enhanceSubdomain")?.addEventListener("change", updateEnhanceTotal);
  document.getElementById("existingDomain")?.addEventListener("input", updateEnhanceTotal);
}

window.addEventListener("DOMContentLoaded", () => {
  setupEventListeners();
  updateRegisterTotal();
  updateEnhanceTotal();
});

// Expose functions for debugging
window.AED_APP = {
  connectWallet,
  registerDomain,
  enhanceDomain,
};
