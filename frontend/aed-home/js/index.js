const DEFAULT_CONTRACT_ADDRESS = "0x6452DCd7Bbee694223D743f09FF07c717Eeb34DF";
const ALSANIA_TLDS = ["aed", "alsa", "07", "alsania", "fx", "echo"];
const ZERO = ethers.BigNumber.from(0);

let provider;
let signer;
let AED;
let pricing = {
  tlds: {},
  features: {}
};

function hasTldPrice(tld) {
  return tld && Object.prototype.hasOwnProperty.call(pricing.tlds, tld);
}

function hasFeaturePrice(featureKey) {
  return Object.prototype.hasOwnProperty.call(pricing.features, featureKey);
}

function getConfiguredAddress() {
  const stored = window.localStorage.getItem("aed:contractAddress");
  return stored && ethers.utils.isAddress(stored) ? stored : DEFAULT_CONTRACT_ADDRESS;
}

function setConfiguredAddress(address) {
  if (ethers.utils.isAddress(address)) {
    window.localStorage.setItem("aed:contractAddress", address);
  }
}

async function loadAbi() {
  const response = await fetch("./js/aedABI.json");
  const abiData = await response.json();
  return abiData.abi || abiData;
}

function formatMatic(value) {
  return Number(ethers.utils.formatEther(value)).toFixed(2);
}

async function connectWallet() {
  try {
    if (!window.ethereum) {
      alert("Please install MetaMask!");
      return;
    }

    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();

    const abi = await loadAbi();
    AED = new ethers.Contract(getConfiguredAddress(), abi, signer);

    const address = await signer.getAddress();
    document.getElementById("wallet").innerText = `Wallet: ${address.slice(0, 6)}...${address.slice(-4)}`;
    document.getElementById("connectBtn").textContent = "Connected";

    setConfiguredAddress(AED.address);

    await refreshPricing();
    updateRegisterTotal();
    updateEnhanceTotal();
  } catch (err) {
    console.error(err);
    alert("Failed to connect wallet: " + err.message);
  }
}

async function refreshPricing() {
  if (!AED) {
    pricing = { tlds: {}, features: {} };
    return;
  }

  const entries = await Promise.all(
    ALSANIA_TLDS.map(async (tld) => {
      const price = await AED.getTLDPrice(tld);
      return [tld, price];
    })
  );

  pricing.tlds = Object.fromEntries(entries);
  pricing.features.subdomain = await AED.getFeaturePrice("subdomain");
  pricing.features.byo = await AED.getFeaturePrice("byo");
}

function resolveSelectedTld() {
  const freeTld = document.getElementById("freeTld").value;
  const featuredTld = document.getElementById("featuredTld").value;
  return (freeTld || featuredTld || "").toLowerCase();
}

function updateRegisterTotal() {
  const selectedTld = resolveSelectedTld();
  const enableSubdomain = document.getElementById("enhSubdomain").checked;

  if (!selectedTld || !AED) {
    document.getElementById("registerTotal").innerText = "Connect for pricing";
    return;
  }

  if (!hasTldPrice(selectedTld) || (enableSubdomain && !hasFeaturePrice("subdomain"))) {
    document.getElementById("registerTotal").innerText = "Loading pricing...";
    return;
  }

  const tldCost = pricing.tlds[selectedTld];
  const enhancementCost = enableSubdomain ? pricing.features.subdomain : ZERO;
  const total = tldCost.add(enhancementCost);

  document.getElementById("registerTotal").innerText = `${formatMatic(total)} MATIC`;
}

function determineEnhancementCost(domain) {
  if (!domain) return ZERO;

  if (/^\d+$/.test(domain)) {
    return hasFeaturePrice("subdomain") ? pricing.features.subdomain : ZERO;
  }

  const normalized = domain.toLowerCase();
  const tld = normalized.includes(".") ? normalized.split(".").pop() : "";
  const isNative = ALSANIA_TLDS.includes(tld);
  if (isNative) {
    return hasFeaturePrice("subdomain") ? pricing.features.subdomain : ZERO;
  }

  return hasFeaturePrice("byo") ? pricing.features.byo : ZERO;
}

function updateEnhanceTotal() {
  const domain = document.getElementById("existingDomain").value.trim();
  const enhance = document.getElementById("enhanceSubdomain").checked;

  if (!enhance || !domain) {
    document.getElementById("enhanceTotal").innerText = "0.00 MATIC";
    return;
  }

  const isTokenId = /^\d+$/.test(domain);
  const requiresNativePricing = isTokenId || ALSANIA_TLDS.some((tld) => domain.toLowerCase().endsWith(`.${tld}`));
  const featureKey = requiresNativePricing ? "subdomain" : "byo";

  if (!hasFeaturePrice(featureKey)) {
    document.getElementById("enhanceTotal").innerText = "Loading pricing...";
    return;
  }

  const total = determineEnhancementCost(domain);
  document.getElementById("enhanceTotal").innerText = `${formatMatic(total)} MATIC`;
}

async function registerDomain() {
  if (!AED) return alert("Connect your wallet first.");

  const name = document.getElementById("domainName").value.trim();
  const tld = resolveSelectedTld();
  const enableSubdomain = document.getElementById("enhSubdomain").checked;

  if (!name || !tld) {
    alert("Please enter a domain name and select a TLD");
    return;
  }

  try {
    const tldPrice = pricing.tlds[tld] || ZERO;
    const enhancementPrice = enableSubdomain ? (pricing.features.subdomain || ZERO) : ZERO;
    const totalFee = tldPrice.add(enhancementPrice);

    const tx = await AED.registerDomain(name, tld, enableSubdomain, {
      value: totalFee
    });
    const receipt = await tx.wait();

    alert("Domain registered successfully! Tx: " + receipt.transactionHash);
    document.getElementById("domainName").value = "";
    document.getElementById("freeTld").value = "";
    document.getElementById("featuredTld").value = "";
    document.getElementById("enhSubdomain").checked = false;
    updateRegisterTotal();
  } catch (err) {
    console.error(err);
    alert("Registration failed: " + (err.reason || err.message));
  }
}

async function enhanceDomain() {
  if (!AED) return alert("Connect your wallet first.");

  const domainInput = document.getElementById("existingDomain").value.trim();
  const enable = document.getElementById("enhanceSubdomain").checked;

  if (!domainInput) return alert("Please enter a domain name or token ID");
  if (!enable) return alert("Please select an enhancement");

  try {
    const isTokenId = /^\d+$/.test(domainInput);
    const normalizedDomain = domainInput.toLowerCase();
    const requiresNativePricing = isTokenId || ALSANIA_TLDS.some((tld) => normalizedDomain.endsWith(`.${tld}`));
    const featureKey = requiresNativePricing ? "subdomain" : "byo";

    if (!hasFeaturePrice(featureKey)) {
      alert("Pricing not loaded yet. Connect your wallet or refresh pricing.");
      return;
    }

    const cost = determineEnhancementCost(domainInput);

    if (isTokenId) {
      const tokenId = BigInt(domainInput);
      const tx = await AED.enableSubdomainFeature(tokenId, { value: cost });
      const receipt = await tx.wait();
      alert("Subdomain feature enabled! Tx: " + receipt.transactionHash);
    } else {
      if (requiresNativePricing) {
        const tokenId = await AED.getTokenIdByDomain(normalizedDomain);
        const tx = await AED.enableSubdomainFeature(tokenId, { value: cost });
        const receipt = await tx.wait();
        alert("Subdomain feature enabled! Tx: " + receipt.transactionHash);
      } else {
        const tx = await AED.upgradeExternalDomain(normalizedDomain, { value: cost });
        const receipt = await tx.wait();
        alert("External domain upgraded! Tx: " + receipt.transactionHash);
      }
    }

    document.getElementById("existingDomain").value = "";
    document.getElementById("enhanceSubdomain").checked = false;
    updateEnhanceTotal();
  } catch (err) {
    console.error(err);
    alert("Enhancement failed: " + (err.reason || err.message));
  }
}

window.addEventListener("DOMContentLoaded", () => {
  document.getElementById("connectBtn").onclick = connectWallet;
  document.getElementById("registerBtn").onclick = registerDomain;
  document.getElementById("enhanceBtn").onclick = enhanceDomain;

  const freeTldSelect = document.getElementById("freeTld");
  const featuredTldSelect = document.getElementById("featuredTld");
  const enhSubdomainCheck = document.getElementById("enhSubdomain");
  const enhanceSubdomainCheck = document.getElementById("enhanceSubdomain");
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

  if (enhSubdomainCheck) {
    enhSubdomainCheck.onchange = updateRegisterTotal;
  }

  if (enhanceSubdomainCheck) {
    enhanceSubdomainCheck.onchange = updateEnhanceTotal;
  }

  if (existingDomainInput) {
    existingDomainInput.oninput = updateEnhanceTotal;
  }
});
