// ===== Configuration =====
const CONTRACT_ADDRESS = '0x3Bf795D47f7B32f36cbB1222805b0E0c5EF066f1';
const AED_ABI = [js/aedABI.json]

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

window.addEventListener('load', connect);

async function registerDomain(){
  const name = val('domainName');
  const tld = val('domainTld');
  const dur = parseInt(val('duration')||'0');
  const fee = parseInt(val('mintFee')||'0');
  const feeEnabled = document.getElementById('feeEnabled').checked;
  const price = await AED.renewalPrice();
  const tx = await AED.registerDomain(name,tld,fee,feeEnabled,dur,{value: price.mul(dur)});
  await tx.wait();
  alert('Domain minted');
}
async function setRoyalty(){
  const bps = parseInt(val('royalty'));
  const tx = await AED.setRoyaltyBps(bps);
  await tx.wait();
  alert('Royalty updated');
}
async function setBaseURI(){
  const uri = val('baseUri');
  const tx = await AED.setBaseURI(uri);
  await tx.wait();
  alert('Base URI updated');
}

async function setMintFee(){
  const fee = parseInt(val('mintFee'));
  const tx = await AED.setMintFee(fee);
  await tx.wait();
  alert('Mint Fee updated');
}
async function reverseLookup(){
  const addr = val('addrLookup');
  const domain = await AED.getReverseDomain(addr);
  document.getElementById('reverseOut').innerText = domain;
}

function val(id){return document.getElementById(id).value;}

async function checkAdminRole() {
  const addr = val('roleAccount');
  const has = await AED.hasRole(await AED.ADMIN_ROLE(), addr);
  alert(addr + (has ? " HAS " : " DOES NOT HAVE ") + "ADMIN ROLE");
}
async function grantAdminRole() {
  const addr = val('roleAccount');
  const tx = await AED.grantRole(await AED.ADMIN_ROLE(), addr);
  await tx.wait();
  alert("Granted ADMIN role");
}
async function revokeAdminRole() {
  const addr = val('roleAccount');
  const tx = await AED.revokeRole(await AED.ADMIN_ROLE(), addr);
  await tx.wait();
  alert("Revoked ADMIN role");
}
async function addGuardian() {
  const id = parseInt(val('guardianTokenId'));
  const addr = val('guardianAddress');
  const tx = await AED.addGuardian(id, addr);
  await tx.wait();
  alert("Guardian added");
}
async function removeGuardian() {
  const id = parseInt(val('guardianTokenId'));
  const addr = val('guardianAddress');
  const tx = await AED.removeGuardian(id, addr);
  await tx.wait();
  alert("Guardian removed");
}
async function initiateRecovery() {
  const id = parseInt(val('recoverId'));
  const tx = await AED.initiateRecovery(id);
  await tx.wait();
  alert("Recovery started");
}
async function completeRecovery() {
  const id = parseInt(val('recoverId'));
  const newOwner = val('recoverNewOwner');
  const tx = await AED.completeRecovery(id, newOwner, []);
  await tx.wait();
  alert("Recovery completed");
}

async function transfer() {
  const id = parseInt(val('transferId'));
  const newOwner = val('transferNewOwner');
  const tx = await AED.transfer(id, newOwner);
  await tx.wait();
  alert("Transfer completed");
}

async function transferFrom() {
  const id = parseInt(val('transferId'));
  const from = val('transferFrom');
  const newOwner = val('transferNewOwner');
  const tx = await AED.transferFrom(from, id, newOwner);
  await tx.wait();
  alert("Transfer completed");
}

async function transferTo() {
  const id = parseInt(val('transferId'));
  const to = val('transferTo');
  const newOwner = val('transferNewOwner');
  const tx = await AED.transferTo(to, id, newOwner);
  await tx.wait();
  alert("Transfer completed");
}

async function transferFromTo() {
  const id = parseInt(val('transferId'));
  const from = val('transferFrom');
  const to = val('transferTo');
  const newOwner = val('transferNewOwner');
  const tx = await AED.transferFromTo(from, to, id, newOwner);
  await tx.wait();
  alert("Transfer completed");
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
  const baseInput = document.getElementById("subdomainBaseFee");
  const feeOutput = document.getElementById("subdomainFee");

  const updateLiveFee = () => {
    const base = parseFloat(baseInput.value) || 0;
    const result = (base * selectedMultiplier).toFixed(4);
    feeOutput.textContent = result;
  };

  // Set default selection
  display.value = "x2";
  selectedMultiplier = 2;
  options.forEach(opt => {
    opt.classList.toggle("selected", opt.dataset.value === "2");
  });
  updateLiveFee();

  display.addEventListener("click", () => {
    dropdown.style.display = dropdown.style.display === "block" ? "none" : "block";
  });

  options.forEach(option => {
    option.addEventListener("click", () => {
      selectedMultiplier = Number(option.dataset.value);
      display.value = option.textContent;
      options.forEach(o => o.classList.remove("selected"));
      option.classList.add("selected");
      dropdown.style.display = "none";
      updateLiveFee();
    });
  });

  baseInput.addEventListener("input", updateLiveFee);

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
