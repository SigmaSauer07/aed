const ALSANIA_TLDS = ["aed", "alsa", "07", "alsania", "fx", "echo"];
let writeProvider;
let readProvider;
let signer;
let AED;
let readOnlyAed;
let abi;

const priceCache = {
  tld: {},
  feature: {},
};

async function loadAbi() {
  if (abi) return abi;
  const response = await fetch("./js/aedABI.json");
  const data = await response.json();
  abi = data.abi || data;
  return abi;
}

function getConfig() {
  if (!window.AED_CONFIG) {
    throw new Error("AED configuration missing");
  }
  return window.AED_CONFIG;
}

async function getReadContract() {
  if (readOnlyAed) return readOnlyAed;
  const config = getConfig();
  const contractAbi = await loadAbi();
  readProvider = readProvider || new ethers.providers.JsonRpcProvider(config.RPC_URL);
  readOnlyAed = new ethers.Contract(config.CONTRACT_ADDRESS, contractAbi, readProvider);
  return readOnlyAed;
}

async function ensureWriteContract() {
  if (AED) return AED;
  if (typeof window.ethereum === "undefined") {
    throw new Error("Wallet provider unavailable");
  }

  await loadAbi();
  writeProvider = new ethers.providers.Web3Provider(window.ethereum, "any");
  const accounts = await writeProvider.send("eth_requestAccounts", []);
  signer = writeProvider.getSigner();

  const config = getConfig();
  const network = await writeProvider.getNetwork();
  const targetChainId = ethers.BigNumber.from(config.NETWORK.chainId);
  if (!network.chainId.eq(targetChainId)) {
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: config.NETWORK.chainId }],
    });
  }

  AED = new ethers.Contract(config.CONTRACT_ADDRESS, abi, signer);
  updateWalletStatus(accounts[0]);
  await refreshPricing();
  return AED;
}

function updateWalletStatus(account) {
  const walletDisplay = document.getElementById("wallet");
  const connectBtn = document.getElementById("connectBtn");
  if (!walletDisplay || !connectBtn) return;

  if (account) {
    const short = `${account.slice(0, 6)}…${account.slice(-4)}`;
    walletDisplay.textContent = `Wallet: ${short}`;
    connectBtn.textContent = "Connected";
    connectBtn.classList.add("connected");
  } else {
    walletDisplay.textContent = "Wallet: Not connected";
    connectBtn.textContent = "Connect Wallet";
    connectBtn.classList.remove("connected");
  }
}

function formatMatic(value) {
  return parseFloat(ethers.utils.formatEther(value)).toFixed(3);
}

async function fetchTldPrice(tld) {
  if (priceCache.tld[tld] !== undefined) {
    return priceCache.tld[tld];
  }
  const contract = await getReadContract();
  const [price, isFree] = await Promise.all([
    contract.getTLDPrice(tld),
    contract.isTldFree(tld),
  ]);
  priceCache.tld[tld] = isFree ? ethers.BigNumber.from(0) : price;
  return priceCache.tld[tld];
}

async function fetchFeaturePrice(feature) {
  if (priceCache.feature[feature] !== undefined) {
    return priceCache.feature[feature];
  }
  const contract = await getReadContract();
  const price = await contract.getFeaturePrice(feature);
  priceCache.feature[feature] = price;
  return price;
}

async function refreshPricing() {
  try {
    const subdomainPrice = await fetchFeaturePrice("subdomain");
    const byoPrice = await fetchFeaturePrice("byo");
    document.getElementById("subdomainPriceLabel").textContent = formatMatic(subdomainPrice);
    document.getElementById("nativeEnhancementPrice").textContent = formatMatic(subdomainPrice);
    document.getElementById("externalEnhancementPrice").textContent = formatMatic(byoPrice);
  } catch (error) {
    console.error("Failed to refresh pricing", error);
  }
  updateRegisterTotal();
  updateEnhanceTotal();
}

async function connectWallet() {
  try {
    await ensureWriteContract();
  } catch (err) {
    console.error(err);
    alert(`Wallet connection failed: ${err.message}`);
  }
}

async function updateRegisterTotal() {
  const freeTldSelect = document.getElementById("freeTld");
  const featuredTldSelect = document.getElementById("featuredTld");
  const subdomainCheck = document.getElementById("enhSubdomain");
  const registerTotal = document.getElementById("registerTotal");

  if (!freeTldSelect || !featuredTldSelect || !registerTotal) return;

  const selectedTld = featuredTldSelect.value || freeTldSelect.value;
  let total = ethers.BigNumber.from(0);

  if (selectedTld) {
    const tldPrice = await fetchTldPrice(selectedTld);
    total = total.add(tldPrice);
  }

  if (subdomainCheck && subdomainCheck.checked) {
    const enhancement = await fetchFeaturePrice("subdomain");
    total = total.add(enhancement);
  }

  registerTotal.textContent = `${formatMatic(total)} MATIC`;
}

async function updateEnhanceTotal() {
  const domainInput = document.getElementById("existingDomain");
  const enhanceCheck = document.getElementById("enhanceSubdomain");
  const enhanceTotal = document.getElementById("enhanceTotal");

  if (!domainInput || !enhanceCheck || !enhanceTotal) return;

  if (!enhanceCheck.checked) {
    enhanceTotal.textContent = "0 MATIC";
    return;
  }

  const domainValue = domainInput.value.trim().toLowerCase();
  const isNative = ALSANIA_TLDS.some((suffix) => domainValue.endsWith(`.${suffix}`));
  const priceKey = isNative ? "subdomain" : "byo";
  const price = await fetchFeaturePrice(priceKey);
  enhanceTotal.textContent = `${formatMatic(price)} MATIC`;
}

async function registerDomain() {
  try {
    const contract = await ensureWriteContract();
    const name = document.getElementById("domainName").value.trim();
    const freeTld = document.getElementById("freeTld").value;
    const featuredTld = document.getElementById("featuredTld").value;
    const selectedTld = featuredTld || freeTld;
    const enableSubdomains = document.getElementById("enhSubdomain").checked;

    if (!name || !selectedTld) {
      alert("Enter a domain name and select a TLD");
      return;
    }

    let total = ethers.BigNumber.from(0);
    total = total.add(await fetchTldPrice(selectedTld));
    if (enableSubdomains) {
      total = total.add(await fetchFeaturePrice("subdomain"));
    }

    const tx = await contract.registerDomain(name, selectedTld, enableSubdomains, { value: total });
    const receipt = await tx.wait();

    alert(`Domain registered! Tx: ${receipt.transactionHash}`);
    document.getElementById("domainName").value = "";
    document.getElementById("freeTld").value = "";
    document.getElementById("featuredTld").value = "";
    document.getElementById("enhSubdomain").checked = false;
    updateRegisterTotal();
  } catch (error) {
    console.error(error);
    alert(`Registration failed: ${error.reason || error.message}`);
  }
}

async function enhanceDomain() {
  try {
    const contract = await ensureWriteContract();
    const domainInput = document.getElementById("existingDomain").value.trim();
    const enhanceCheck = document.getElementById("enhanceSubdomain");

    if (!domainInput) {
      alert("Enter a domain name or token ID");
      return;
    }
    if (!enhanceCheck.checked) {
      alert("Select an enhancement option");
      return;
    }

    const domainValue = domainInput.toLowerCase();
    const isNative = ALSANIA_TLDS.some((suffix) => domainValue.endsWith(`.${suffix}`));
    let tokenId = null;

    if (/^\d+$/.test(domainInput)) {
      tokenId = ethers.BigNumber.from(domainInput);
    } else {
      try {
        tokenId = await contract.getTokenIdByDomain(domainValue);
      } catch (lookupError) {
        tokenId = null;
      }
    }

    if (tokenId !== null) {
      const price = await fetchFeaturePrice("subdomain");
      const tx = await contract.purchaseFeature(tokenId, "subdomain", { value: price });
      const receipt = await tx.wait();
      alert(`Enhancement confirmed! Tx: ${receipt.transactionHash}`);
    } else {
      const price = await fetchFeaturePrice("byo");
      const tx = await contract.upgradeExternalDomain(domainValue, { value: price });
      const receipt = await tx.wait();
      alert(`External upgrade confirmed! Tx: ${receipt.transactionHash}`);
    }

    document.getElementById("existingDomain").value = "";
    enhanceCheck.checked = false;
    updateEnhanceTotal();
  } catch (error) {
    console.error(error);
    alert(`Enhancement failed: ${error.reason || error.message}`);
  }
}

window.addEventListener("DOMContentLoaded", async () => {
  document.getElementById("connectBtn").addEventListener("click", connectWallet);
  document.getElementById("registerBtn").addEventListener("click", registerDomain);
  document.getElementById("enhanceBtn").addEventListener("click", enhanceDomain);

  if (window.ethereum && typeof window.ethereum.on === "function") {
    window.ethereum.on("accountsChanged", (accounts) => {
      updateWalletStatus(accounts && accounts.length ? accounts[0] : null);
    });
    window.ethereum.on("chainChanged", () => {
      priceCache.tld = {};
      priceCache.feature = {};
      refreshPricing();
    });
  }

  ["freeTld", "featuredTld"].forEach((id) => {
    const element = document.getElementById(id);
    if (element) {
      element.addEventListener("change", () => {
        if (id === "freeTld") {
          document.getElementById("featuredTld").value = "";
        } else {
          document.getElementById("freeTld").value = "";
        }
        updateRegisterTotal();
      });
    }
  });

  const subdomainToggle = document.getElementById("enhSubdomain");
  if (subdomainToggle) {
    subdomainToggle.addEventListener("change", updateRegisterTotal);
  }

  const enhanceToggle = document.getElementById("enhanceSubdomain");
  if (enhanceToggle) {
    enhanceToggle.addEventListener("change", updateEnhanceTotal);
  }

  const existingDomainInput = document.getElementById("existingDomain");
  if (existingDomainInput) {
    existingDomainInput.addEventListener("input", updateEnhanceTotal);
  }

  await refreshPricing();
});
