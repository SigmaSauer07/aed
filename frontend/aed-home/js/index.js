const CONTRACT_ADDRESS = '0x8dc59aA8e9AA8B9fd01AF747608B4a28b728F539'; // Updated Amoy proxy address
let provider, signer, AED;

// Alsania native TLDs
const ALSANIA_TLDS = ['aed', 'alsa', '07', 'alsania', 'fx', 'echo'];

async function connectWallet() {
  try {
    if (!window.ethereum) {
      alert("Please install MetaMask!");
      return;
    }

    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();
    
    // Load ABI
    const response = await fetch('./js/aedABI.json');
    const abiData = await response.json();
    const abi = abiData.abi || abiData; // Handle different ABI formats
    
    AED = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);
    const address = await signer.getAddress();
    document.getElementById("wallet").innerText = "Wallet: " + address.slice(0, 6) + "..." + address.slice(-4);
    
    // Update button text
    document.getElementById("connectBtn").textContent = "Connected";
    
    await updateRegisterTotal();
  } catch (err) {
    console.error(err);
    alert("Failed to connect wallet: " + err.message);
  }
}

async function updateRegisterTotal() {
  const freeTld = document.getElementById("freeTld").value;
  const featuredTld = document.getElementById("featuredTld").value;
  const subEnh = document.getElementById("enhSubdomain").checked;
  
  let total = 0;
  let selectedTld = freeTld || featuredTld;
  
  if (selectedTld && AED) {
    try {
      // For now, we'll use estimated prices since getTLDPrice might not exist
      // Free TLDs = 0, Featured TLDs = estimated price
      if (featuredTld) {
        total = 5; // Estimated price for featured TLDs
      }
      
      if (subEnh) {
        total += 2;
      }
    } catch (err) {
      console.error("Error calculating price:", err);
    }
  } else if (subEnh) {
    total = 2;
  }
  
  document.getElementById("registerTotal").innerText = `$${total} MATIC`;
}

function updateEnhanceTotal() {
  const domain = document.getElementById("existingDomain").value.trim();
  const enhance = document.getElementById("enhanceSubdomain").checked;
  
  let total = 0;
  
  if (enhance && domain) {
    // Check if it's an Alsania native domain
    const isNative = ALSANIA_TLDS.some(tld => domain.toLowerCase().includes(`.${tld}`));
    total = isNative ? 2 : 5;
  }
  
  document.getElementById("enhanceTotal").innerText = `$${total} MATIC`;
}

async function registerDomain() {
  if (!AED) return alert(" Connect your wallet first.");
  
  const name = document.getElementById("domainName").value.trim();
  const freeTld = document.getElementById("freeTld").value;
  const featuredTld = document.getElementById("featuredTld").value;
  const selectedTld = freeTld || featuredTld;
  const enh = document.getElementById("enhSubdomain").checked;
  
  if (!name || !selectedTld) return alert(" Please enter a domain name and select a TLD");
  
  try {
    // Calculate total fee
    let tldPrice = 0n;
    if (featuredTld) {
      tldPrice = ethers.parseEther("1"); // Updated to $1 MATIC for featured TLDs
    }
    
    const subFee = enh ? ethers.parseEther("2") : 0n;
    const totalFee = tldPrice + subFee;

    // Use the correct function signature based on the contract
    const tx = await AED.registerDomain(name, selectedTld, enh, {
      value: totalFee
    });
    
    const receipt = await tx.wait();
    alert(" Domain registered successfully! Tx: " + receipt.transactionHash);
    
    // Clear form
    document.getElementById("domainName").value = "";
    document.getElementById("freeTld").value = "";
    document.getElementById("featuredTld").value = "";
    document.getElementById("enhSubdomain").checked = false;
    updateRegisterTotal();
    
  } catch (err) {
    console.error(err);
    alert(" Registration failed: " + (err.reason || err.message));
  }
}

async function enhanceDomain() {
  if (!AED) return alert(" Connect your wallet first.");
  
  const domain = document.getElementById("existingDomain").value.trim();
  const enhance = document.getElementById("enhanceSubdomain").checked;
  
  if (!domain) return alert(" Please enter a domain name or token ID");
  if (!enhance) return alert(" Please select an enhancement");
  
  try {
    // Determine if it's a token ID or domain name
    const isTokenId = /^\d+$/.test(domain);
    let tokenId;
    
    if (isTokenId) {
      tokenId = BigInt(domain);
    } else {
      try {
        // Try to get token ID from domain name
        tokenId = await AED.getTokenIdByDomain(domain);
      } catch (err) {
        alert("Could not find token ID for domain. Please use Token ID instead.");
        return;
      }
    }
    
    // Calculate fee
    const isNative = ALSANIA_TLDS.some(tld => domain.toLowerCase().includes(`.${tld}`));
    const fee = ethers.parseEther(isNative ? "2" : "5");
    
    // Purchase subdomain feature
    const tx = await AED.purchaseFeature(tokenId, "subdomain", { value: fee });
    const receipt = await tx.wait();
    
    alert(" Domain enhanced successfully! Tx: " + receipt.transactionHash);
    
    // Clear form
    document.getElementById("existingDomain").value = "";
    document.getElementById("enhanceSubdomain").checked = false;
    updateEnhanceTotal();
    
  } catch (err) {
    console.error(err);
    alert(" Enhancement failed: " + (err.reason || err.message));
  }
}

// Event listeners
window.addEventListener("DOMContentLoaded", () => {
  document.getElementById("connectBtn").onclick = connectWallet;
  document.getElementById("registerBtn").onclick = registerDomain;
  document.getElementById("enhanceBtn").onclick = enhanceDomain;
  
  // Update totals when selections change
  // Add event listeners for TLD selection
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

