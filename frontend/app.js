const ABI = [];
const CONTRACT_ADDRESS = "0x...";
const provider = new ethers.BrowserProvider(window.ethereum);
let signer, contract;

async function connect() {
  await provider.send("eth_requestAccounts", []);
  signer = await provider.getSigner();
  contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
  document.getElementById("status").textContent = "Wallet connected";
}

async function mintDomain() {
  const name = document.getElementById("domain").value;
  const tx = await contract.mintRootDomain(name);
  await tx.wait();
  alert("Domain minted: " + name + ".fx");
}
