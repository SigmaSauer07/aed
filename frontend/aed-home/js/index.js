const DEFAULT_CONFIG = {
  contractAddress: "0x6452DCd7Bbee694223D743f09FF07c717Eeb34DF",
  network: {
    name: "Polygon Amoy",
    chainIdHex: "0x13882",
    rpcUrl: "https://rpc-amoy.polygon.technology"
  },
  pricing: {
    fallbackPremiumTld: "1",
    fallbackSubdomain: "2",
    fallbackByo: "5"
  }
};

function deepMerge(base, override) {
  const output = { ...base };
  for (const key of Object.keys(override || {})) {
    const value = override[key];
    if (value && typeof value === "object" && !Array.isArray(value)) {
      output[key] = deepMerge(base[key] || {}, value);
    } else if (value !== undefined) {
      output[key] = value;
    }
  }
  return output;
}

const CONFIG = deepMerge(DEFAULT_CONFIG, window.AED_CONFIG || {});
const CONTRACT_ADDRESS = CONFIG.contractAddress;
const TARGET_CHAIN_ID_HEX = CONFIG.network.chainIdHex;
const TARGET_CHAIN_ID = parseInt(TARGET_CHAIN_ID_HEX, 16);
const TARGET_CHAIN_ID_BIGINT = BigInt(TARGET_CHAIN_ID);

const ALSANIA_TLDS = ["aed", "alsa", "07", "alsania", "fx", "echo"];
const FREE_TLDS = new Set(["aed", "alsa", "07"]);

let provider;
let signer;
let AED;
let readProvider = CONFIG.network.rpcUrl ? new ethers.JsonRpcProvider(CONFIG.network.rpcUrl) : null;
let contractAbi;

const pricingCache = new Map();

async function loadAbi() {
  if (!contractAbi) {
    const response = await fetch("./js/aedABI.json");
    const data = await response.json();
    contractAbi = data.abi || data;
  }
  return contractAbi;
}

async function getReadContract() {
  const abi = await loadAbi();
  if (!readProvider && CONFIG.network.rpcUrl) {
    readProvider = new ethers.JsonRpcProvider(CONFIG.network.rpcUrl);
  }
  const runner = signer || provider || readProvider;
  if (!runner) {
    throw new Error("No provider available for read operations");
  }
  return new ethers.Contract(CONTRACT_ADDRESS, abi, runner);
}

async function ensureCorrectNetwork() {
  if (!provider) return;
  const network = await provider.getNetwork();
  if (network.chainId === TARGET_CHAIN_ID_BIGINT) {
    return;
  }

  try {
    await provider.send("wallet_switchEthereumChain", [{ chainId: TARGET_CHAIN_ID_HEX }]);
  } catch (switchError) {
    if (switchError.code === 4902) {
      await provider.send("wallet_addEthereumChain", [{
        chainId: TARGET_CHAIN_ID_HEX,
        chainName: CONFIG.network.name,
        rpcUrls: [CONFIG.network.rpcUrl],
        nativeCurrency: { name: "MATIC", symbol: "MATIC", decimals: 18 }
      }]);
    } else {
      throw switchError;
    }
  }
}
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
    if (!window.ethereum) {
      alert("Please install MetaMask to continue.");
      return;
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
    await provider.send("eth_requestAccounts", []);
    await ensureCorrectNetwork();

    signer = await provider.getSigner();
    const abi = await loadAbi();
    AED = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);

    const address = await signer.getAddress();
    document.getElementById("wallet").innerText = `Wallet: ${address.slice(0, 6)}...${address.slice(-4)}`;
    document.getElementById("connectBtn").textContent = "Connected";

    await updateRegisterTotal();
    await updateEnhanceTotal();
  } catch (err) {
    console.error(err);
    alert(`Failed to connect wallet: ${err.message}`);
  }
}

function isNativeDomain(domain) {
  const lower = domain.toLowerCase();
  return ALSANIA_TLDS.some((tld) => lower.endsWith(`.${tld}`));
}

function fallbackTldPricing(tld) {
  if (FREE_TLDS.has(tld)) {
    return { price: 0n, isFree: true };
  }

  if (ALSANIA_TLDS.includes(tld)) {
    return { price: ethers.parseEther(CONFIG.pricing.fallbackPremiumTld), isFree: false };
  }

  return { price: 0n, isFree: false };
}

function formatMatic(amountWei) {
  try {
    const formatted = Number.parseFloat(ethers.formatEther(amountWei ?? 0n));
    return `$${formatted.toFixed(2)} MATIC`;
  } catch (err) {
    return "$0.00 MATIC";
  }
}

async function resolveTldPricing(tld) {
  if (!tld) {
    return { price: 0n, isFree: true };
  }

  const cacheKey = `tld-${tld}`;
  if (pricingCache.has(cacheKey)) {
    return pricingCache.get(cacheKey);
  }

  try {
    const contract = await getReadContract();
    const [price, isFree] = await Promise.all([
      contract.getTLDPrice(tld),
      contract.isTLDFree(tld)
    ]);
    const payload = { price, isFree };
    pricingCache.set(cacheKey, payload);
    return payload;
  } catch (err) {
    console.warn(`Falling back to static pricing for ${tld}:`, err.message);
    const payload = fallbackTldPricing(tld);
    pricingCache.set(cacheKey, payload);
    return payload;
  }
}

async function getFeaturePriceValue(featureName) {
  const cacheKey = `feature-${featureName}`;
  if (pricingCache.has(cacheKey)) {
    return pricingCache.get(cacheKey);
  }

  try {
    const contract = await getReadContract();
    const price = await contract.getFeaturePrice(featureName);
    pricingCache.set(cacheKey, price);
    return price;
  } catch (err) {
    console.warn(`Using fallback pricing for feature ${featureName}:`, err.message);
    let fallback = "0";
    if (featureName === "subdomain") {
      fallback = CONFIG.pricing.fallbackSubdomain;
    } else if (featureName === "byo") {
      fallback = CONFIG.pricing.fallbackByo;
    }
    const price = ethers.parseEther(fallback);
    pricingCache.set(cacheKey, price);
    return price;
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
  const totalElement = document.getElementById("registerTotal");
  if (!totalElement) return;

  try {
    const freeTldSelect = document.getElementById("freeTld");
    const featuredTldSelect = document.getElementById("featuredTld");
    const subdomainCheckbox = document.getElementById("enhSubdomain");

    const selectedFree = freeTldSelect ? freeTldSelect.value : "";
    const selectedFeatured = featuredTldSelect ? featuredTldSelect.value : "";
    const selectedTld = selectedFree || selectedFeatured;
    const wantsSubdomains = subdomainCheckbox ? subdomainCheckbox.checked : false;

    let totalWei = 0n;

    if (selectedTld) {
      const tldInfo = await resolveTldPricing(selectedTld);
      if (!tldInfo.isFree) {
        totalWei += tldInfo.price;
      }
    }

    if (wantsSubdomains) {
      totalWei += await getFeaturePriceValue("subdomain");
    }

    totalElement.innerText = formatMatic(totalWei);
  } catch (err) {
    console.error("Failed to update registration total", err);
    totalElement.innerText = "$0.00 MATIC";
  }
}

async function updateEnhanceTotal() {
  const totalElement = document.getElementById("enhanceTotal");
  if (!totalElement) return;

  try {
    const domainInput = document.getElementById("existingDomain");
    const enhanceCheckbox = document.getElementById("enhanceSubdomain");

    const domainValue = domainInput ? domainInput.value.trim() : "";
    const wantsEnhancement = enhanceCheckbox ? enhanceCheckbox.checked : false;

    let totalWei = 0n;

    if (wantsEnhancement) {
      const native = domainValue ? isNativeDomain(domainValue) : true;
      const priceKey = native ? "subdomain" : "byo";
      totalWei += await getFeaturePriceValue(priceKey);
    }

    totalElement.innerText = formatMatic(totalWei);
  } catch (err) {
    console.error("Failed to update enhancement total", err);
    totalElement.innerText = "$0.00 MATIC";
  }
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
    alert("Connect your wallet first.");
    alert("Connect your wallet before registering.");
    return;
  }

  const nameInput = document.getElementById("domainName");
  const freeTldSelect = document.getElementById("freeTld");
  const featuredTldSelect = document.getElementById("featuredTld");
  const subdomainCheckbox = document.getElementById("enhSubdomain");

  const name = nameInput ? nameInput.value.trim() : "";
  const selectedFree = freeTldSelect ? freeTldSelect.value : "";
  const selectedFeatured = featuredTldSelect ? featuredTldSelect.value : "";
  const selectedTld = selectedFree || selectedFeatured;
  const wantsSubdomains = subdomainCheckbox ? subdomainCheckbox.checked : false;
  const name = (nameInput?.value || "").trim();
  const selectedTld = getSelectedTld();
  const withSubdomains = document.getElementById("enhSubdomain")?.checked || false;

  if (!name || !selectedTld) {
    alert("Please enter a domain name and select a TLD.");
    return;
  }

  try {
    const tldInfo = await resolveTldPricing(selectedTld);
    let totalFee = tldInfo.isFree ? 0n : tldInfo.price;

    if (wantsSubdomains) {
      totalFee += await getFeaturePriceValue("subdomain");
    }

    const overrides = totalFee > 0n ? { value: totalFee } : {};
    const tx = await AED.registerDomain(name, selectedTld, wantsSubdomains, overrides);
    const receipt = await tx.wait();

    alert(`Domain registered successfully! Tx: ${receipt.hash}`);

    if (nameInput) nameInput.value = "";
    if (freeTldSelect) freeTldSelect.value = "";
    if (featuredTldSelect) featuredTldSelect.value = "";
    if (subdomainCheckbox) subdomainCheckbox.checked = false;

    await updateRegisterTotal();
  } catch (err) {
    console.error(err);
    alert(`Registration failed: ${err.reason || err.message}`);
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
    alert("Connect your wallet first.");
    return;
  }

  const domainInput = document.getElementById("existingDomain");
  const enhanceCheckbox = document.getElementById("enhanceSubdomain");

  const domain = domainInput ? domainInput.value.trim() : "";
  const wantsEnhancement = enhanceCheckbox ? enhanceCheckbox.checked : false;

  if (!domain) {
    alert("Please enter a domain name or token ID.");
    return;
  }

  if (!wantsEnhancement) {
    alert("Please select an enhancement.");
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
    const isTokenId = /^\d+$/.test(domain);
    let tokenId;

    if (isTokenId) {
      tokenId = BigInt(domain);
    } else {
      try {
        const contract = await getReadContract();
        tokenId = await contract.getTokenIdByDomain(domain);
      } catch (err) {
        alert("Could not resolve token ID for that domain. Please provide the Token ID directly.");
        return;
      }
    }

    const native = isTokenId ? true : isNativeDomain(domain);
    const featureKey = native ? "subdomain" : "byo";
    const price = await getFeaturePriceValue(featureKey);
    const overrides = price > 0n ? { value: price } : {};

    let tx;
    if (native) {
      tx = await AED.purchaseFeature(tokenId, "subdomain", overrides);
    } else {
      tx = await AED.upgradeExternalDomain(domain, overrides);
    }

    const receipt = await tx.wait();
    alert(`Domain enhanced successfully! Tx: ${receipt.hash}`);

    if (domainInput) domainInput.value = "";
    if (enhanceCheckbox) enhanceCheckbox.checked = false;

    await updateEnhanceTotal();
  } catch (err) {
    console.error(err);
    alert(`Enhancement failed: ${err.reason || err.message}`);
  }
}

window.addEventListener("DOMContentLoaded", () => {
  document.getElementById("connectBtn").onclick = () => connectWallet();
  document.getElementById("registerBtn").onclick = () => registerDomain();
  document.getElementById("enhanceBtn").onclick = () => enhanceDomain();

  const freeTldSelect = document.getElementById("freeTld");
  const featuredTldSelect = document.getElementById("featuredTld");
  const subdomainCheckbox = document.getElementById("enhSubdomain");
  const enhanceCheckbox = document.getElementById("enhanceSubdomain");
  const existingDomainInput = document.getElementById("existingDomain");

  if (freeTldSelect) {
    freeTldSelect.onchange = () => {
      if (freeTldSelect.value && featuredTldSelect) {
        featuredTldSelect.value = "";
      }
      updateRegisterTotal();
    };
  }

  if (featuredTldSelect) {
    featuredTldSelect.onchange = () => {
      if (featuredTldSelect.value && freeTldSelect) {
        freeTldSelect.value = "";
      }
      updateRegisterTotal();
    };
  }

  if (subdomainCheckbox) {
    subdomainCheckbox.onchange = () => updateRegisterTotal();
  }

  if (enhanceCheckbox) {
    enhanceCheckbox.onchange = () => updateEnhanceTotal();
  }

  if (existingDomainInput) {
    existingDomainInput.oninput = () => updateEnhanceTotal();
  }

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

window.connectWallet = connectWallet;
window.registerDomain = registerDomain;
window.enhanceDomain = enhanceDomain;
// Expose functions for debugging
window.AED_APP = {
  connectWallet,
  registerDomain,
  enhanceDomain,
};
