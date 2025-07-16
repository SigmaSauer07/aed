const CONTRACT_ADDRESS = '0x3Bf795D47f7B32f36cbB1222805b0E0c5EF066f1';
let provider, signer, AED;

// Alsania native TLDs
const ALSANIA_TLDS = ['aed', 'alsa', '07', 'alsania', 'fx', 'echo'];

async function connectWallet() {
  try {
    provider = new ethers.providers.Web3Provider(window.ethereum, "any");
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    
    // Load ABI
    const response = await fetch('aedABI.json');
    const abi = await response.json();
    
    AED = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);
    const address = await signer.getAddress();
    document.getElementById("wallet").innerText = "Wallet: " + address.slice(0, 6) + "..." + address.slice(-4);
    
    await updateRegisterTotal();
  } catch (err) {
    console.error(err);
    alert(" Failed to connect wallet: " + err.message);
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
    let tldPrice = ethers.BigNumber.from(0);
    if (featuredTld) {
      tldPrice = ethers.utils.parseEther("5"); // Estimated price for featured TLDs
    }
    
    const subFee = enh ? ethers.utils.parseEther("2") : ethers.BigNumber.from(0);
    const totalFee = tldPrice.add(subFee);
    const duration = ethers.BigNumber.from("3153600000"); // 100 years

    // Estimate gas
    let gasLimit;
    try {
      const est = await AED.estimateGas.registerDomain(name, selectedTld, subFee, enh, duration, { value: totalFee });
      gasLimit = est.mul(12).div(10);
    } catch {
      gasLimit = ethers.BigNumber.from(500000);
    }

    const tx = await AED.registerDomain(name, selectedTld, subFee, enh, duration, { 
      value: totalFee, 
      gasLimit 
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
      tokenId = ethers.BigNumber.from(domain);
    } else {
      // For domain names, you'd need to implement domain to token ID lookup
      // This is a placeholder - you'll need to implement this based on your contract
      alert(" Domain name lookup not implemented yet. Please use Token ID.");
      return;
    }
    
    // Calculate fee
    const isNative = ALSANIA_TLDS.some(tld => domain.toLowerCase().includes(`.${tld}`));
    const fee = ethers.utils.parseEther(isNative ? "2" : "5");
    
    // Purchase feature (assuming feature code 1 is for subdomains)
    const tx = await AED.purchaseFeature(tokenId, 1, { value: fee });
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
  document.getElementById("freeTld").onchange = () => {
    if (document.getElementById("freeTld").value) {
      document.getElementById("featuredTld").value = "";
    }
    updateRegisterTotal();
  };
  
  document.getElementById("featuredTld").onchange = () => {
    if (document.getElementById("featuredTld").value) {
      document.getElementById("freeTld").value = "";
    }
    updateRegisterTotal();
  };
  
  document.getElementById("enhSubdomain").onchange = updateRegisterTotal;
  document.getElementById("enhanceSubdomain").onchange = updateEnhanceTotal;
  document.getElementById("existingDomain").oninput = updateEnhanceTotal;
});

