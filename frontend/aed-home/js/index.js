const CONFIG = window.AED_CONFIG || {};
const CONTRACT_ADDRESS = CONFIG.contractAddress;
const TARGET_CHAIN_ID = CONFIG.chainId ? CONFIG.chainId.toLowerCase() : undefined;

let provider;
let signer;
let AED;

const ALSANIA_TLDS = ["aed", "alsa", "07", "alsania", "fx", "echo"];
const tldPriceCache = {};
let subdomainPrice = 0n;
let byoUpgradePrice = 0n;

function requireConfig() {
  if (!CONTRACT_ADDRESS) {
    throw new Error("AED contract address missing in frontend/config/config.js");
  }
}

function formatMatic(value) {
  const wei = typeof value === "bigint" ? value : BigInt(value || 0);
  const formatted = Number.parseFloat(ethers.formatEther(wei));
  return formatted === 0 ? "0" : formatted.toFixed(3).replace(/\.0+$/, "").replace(/(\.\d*[1-9])0+$/, "$1");
}

async function ensureCorrectNetwork() {
  if (!TARGET_CHAIN_ID || !window.ethereum) {
    return;
  }

  const currentChain = (await window.ethereum.request({ method: "eth_chainId" })).toLowerCase();
  if (currentChain === TARGET_CHAIN_ID) {
    return;
  }

  try {
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: TARGET_CHAIN_ID }],
    });
  } catch (switchError) {
    if (switchError.code === 4902 && CONFIG.rpcUrl) {
      await window.ethereum.request({
        method: "wallet_addEthereumChain",
        params: [{
          chainId: TARGET_CHAIN_ID,
          rpcUrls: [CONFIG.rpcUrl],
          chainName: CONFIG.networkName || "Polygon Amoy",
          nativeCurrency: {
            name: "MATIC",
            symbol: "MATIC",
            decimals: 18,
          },
          blockExplorerUrls: ["https://amoy.polygonscan.com"],
        }],
      });
    } else {
      throw switchError;
    }
  }
}

async function connectWallet() {
  try {
    requireConfig();

    if (!window.ethereum) {
      alert("Please install a Web3 wallet such as MetaMask.");
      return;
    }

    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    await ensureCorrectNetwork();
    signer = await provider.getSigner();

    const abiResponse = await fetch("./js/aedABI.json");
    const abiPayload = await abiResponse.json();
    const abi = abiPayload.abi || abiPayload;
    AED = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);

    const address = await signer.getAddress();
    document.getElementById("wallet").innerText = `Wallet: ${address.slice(0, 6)}...${address.slice(-4)}`;
    document.getElementById("connectBtn").textContent = "Connected";

    await loadPricing();
    await updateRegisterTotal();
    updateEnhanceTotal();
  } catch (err) {
    console.error(err);
    alert(`Failed to connect wallet: ${err.message || err}`);
  }
}

async function loadPricing() {
  if (!AED) return;

  try {
    subdomainPrice = BigInt(await AED.getFeaturePrice("subdomain"));
    byoUpgradePrice = BigInt(await AED.getFeaturePrice("byo"));

    document.getElementById("subdomainPriceLabel").innerText = formatMatic(subdomainPrice);
    document.getElementById("nativeEnhPrice").innerText = formatMatic(subdomainPrice);
    document.getElementById("externalEnhPrice").innerText = formatMatic(byoUpgradePrice);
    document.getElementById("externalUpgradeLabel").innerText = formatMatic(byoUpgradePrice);

    for (const tld of ALSANIA_TLDS) {
      const isActive = await AED.isTLDActive(tld);
      if (!isActive) {
        delete tldPriceCache[tld];
        continue;
      }

      const price = BigInt(await AED.getTLDPrice(tld));
      tldPriceCache[tld] = price;
    }

    updateTldOptionLabels();
    document.getElementById("premiumTldLabel").innerText = formatMatic(tldPriceCache["alsania"] || 0n);
    document.getElementById("freeTldLabel").innerText = formatMatic(0n);
  } catch (error) {
    console.error("Failed to load pricing", error);
  }
}

function updateTldOptionLabels() {
  const freeSelect = document.getElementById("freeTld");
  const premiumSelect = document.getElementById("featuredTld");

  if (freeSelect) {
    Array.from(freeSelect.options).forEach((option) => {
      const value = option.value.toLowerCase();
      if (!value) return;
      const price = tldPriceCache[value] || 0n;
      option.textContent = `.${value} (${formatMatic(price)} MATIC)`;
    });
  }

  if (premiumSelect) {
    Array.from(premiumSelect.options).forEach((option) => {
      const value = option.value.toLowerCase();
      if (!value) return;
      const price = tldPriceCache[value] || 0n;
      option.textContent = `.${value} (${formatMatic(price)} MATIC)`;
    });
  }
}

async function updateRegisterTotal() {
  const freeTld = document.getElementById("freeTld").value.toLowerCase();
  const featuredTld = document.getElementById("featuredTld").value.toLowerCase();
  const subEnh = document.getElementById("enhSubdomain").checked;

  let total = 0n;
  const selectedTld = freeTld || featuredTld;

  if (selectedTld) {
    const cached = tldPriceCache[selectedTld];
    if (cached === undefined && AED) {
      try {
        const price = BigInt(await AED.getTLDPrice(selectedTld));
        tldPriceCache[selectedTld] = price;
        total += price;
      } catch (error) {
        console.error("Unable to fetch TLD price", error);
      }
    } else if (cached !== undefined) {
      total += cached;
    }
  }

  if (subEnh) {
    total += subdomainPrice;
  }

  document.getElementById("registerTotal").innerText = `${formatMatic(total)} MATIC`;
}

function updateEnhanceTotal() {
  const domainInput = document.getElementById("existingDomain").value.trim().toLowerCase();
  const enhance = document.getElementById("enhanceSubdomain").checked;

  if (!enhance || !domainInput) {
    document.getElementById("enhanceTotal").innerText = "0 MATIC";
    return;
  }

  const parts = domainInput.split(".");
  const tld = parts.length > 1 ? parts[parts.length - 1] : "";
  const isNative = ALSANIA_TLDS.includes(tld);
  const fee = isNative ? subdomainPrice : byoUpgradePrice;

  document.getElementById("enhanceTotal").innerText = `${formatMatic(fee)} MATIC`;
}

async function registerDomain() {
  if (!AED) {
    alert("Connect your wallet first.");
    return;
  }

  const name = document.getElementById("domainName").value.trim();
  const freeTld = document.getElementById("freeTld").value.toLowerCase();
  const featuredTld = document.getElementById("featuredTld").value.toLowerCase();
  const selectedTld = freeTld || featuredTld;
  const withSubdomains = document.getElementById("enhSubdomain").checked;

  if (!name || !selectedTld) {
    alert("Please enter a domain name and select a TLD.");
    return;
  }

  try {
    const baseCost = tldPriceCache[selectedTld] ?? BigInt(await AED.getTLDPrice(selectedTld));
    tldPriceCache[selectedTld] = baseCost;

    const totalFee = baseCost + (withSubdomains ? subdomainPrice : 0n);

    const tx = await AED.registerDomain(name, selectedTld, withSubdomains, {
      value: totalFee,
    });

    const receipt = await tx.wait();
    alert(`Domain registered successfully! Tx: ${receipt.transactionHash}`);

    document.getElementById("domainName").value = "";
    document.getElementById("freeTld").value = "";
    document.getElementById("featuredTld").value = "";
    document.getElementById("enhSubdomain").checked = false;
    await updateRegisterTotal();
  } catch (error) {
    console.error(error);
    alert(`Registration failed: ${error.reason || error.message || error}`);
  }
}

async function enhanceDomain() {
  if (!AED) {
    alert("Connect your wallet first.");
    return;
  }

  const domainOrId = document.getElementById("existingDomain").value.trim();
  const enhance = document.getElementById("enhanceSubdomain").checked;

  if (!domainOrId) {
    alert("Please enter a domain name or token ID.");
    return;
  }
  if (!enhance) {
    alert("Please select an enhancement option.");
    return;
  }

  try {
    let tokenId;
    if (/^\d+$/.test(domainOrId)) {
      tokenId = BigInt(domainOrId);
    } else {
      tokenId = await AED.getTokenIdByDomain(domainOrId.toLowerCase());
    }

    const parts = domainOrId.toLowerCase().split(".");
    const tld = parts.length > 1 ? parts[parts.length - 1] : "";
    const isNative = ALSANIA_TLDS.includes(tld);
    const fee = isNative ? subdomainPrice : byoUpgradePrice;

    const tx = await AED.purchaseFeature(tokenId, "subdomain", { value: fee });
    const receipt = await tx.wait();

    alert(`Domain enhanced successfully! Tx: ${receipt.transactionHash}`);

    document.getElementById("existingDomain").value = "";
    document.getElementById("enhanceSubdomain").checked = false;
    updateEnhanceTotal();
  } catch (error) {
    console.error(error);
    alert(`Enhancement failed: ${error.reason || error.message || error}`);
  }
}

window.addEventListener("DOMContentLoaded", () => {
  document.getElementById("connectBtn").addEventListener("click", connectWallet);
  document.getElementById("registerBtn").addEventListener("click", registerDomain);
  document.getElementById("enhanceBtn").addEventListener("click", enhanceDomain);

  const freeTldSelect = document.getElementById("freeTld");
  const featuredTldSelect = document.getElementById("featuredTld");
  const enhSubdomainCheck = document.getElementById("enhSubdomain");
  const enhanceSubdomainCheck = document.getElementById("enhanceSubdomain");
  const existingDomainInput = document.getElementById("existingDomain");

  if (freeTldSelect) {
    freeTldSelect.addEventListener("change", () => {
      if (freeTldSelect.value && featuredTldSelect) {
        featuredTldSelect.value = "";
      }
      updateRegisterTotal();
    });
  }

  if (featuredTldSelect) {
    featuredTldSelect.addEventListener("change", () => {
      if (featuredTldSelect.value && freeTldSelect) {
        freeTldSelect.value = "";
      }
      updateRegisterTotal();
    });
  }

  if (enhSubdomainCheck) {
    enhSubdomainCheck.addEventListener("change", updateRegisterTotal);
  }

  if (enhanceSubdomainCheck) {
    enhanceSubdomainCheck.addEventListener("change", updateEnhanceTotal);
  }

  if (existingDomainInput) {
    existingDomainInput.addEventListener("input", updateEnhanceTotal);
  }
});
