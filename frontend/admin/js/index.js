
import abi from './aedABI.json' assert {type: 'json'};
const address = '0xF331AA1dAe471c2e77C1ed98dB36bC2e25f36D9f';

let provider, signer, AED;

async function connect() {
  if(!window.ethereum) return alert('MetaMask required');
  provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send('eth_requestAccounts', []);
  signer = provider.getSigner();
  AED = new ethers.Contract(address, abi, signer);
  document.getElementById('wallet').innerText = 'Wallet: ' + await signer.getAddress();
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
async function renewDomain(){
  const id = parseInt(val('renewId'));
  const dur = parseInt(val('renewDur'));
  const price = await AED.renewalPrice();
  const tx = await AED.renewDomain(id,dur,{value: price.mul(dur)});
  await tx.wait();
  alert('Renewed');
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
