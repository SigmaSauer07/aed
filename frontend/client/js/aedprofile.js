const CONTRACT_ADDRESS = '0x3Bf795D47f7B32f36cbB1222805b0E0c5EF066f1';
let provider, signer, AED;

async function connectWallet() {
  try {
    provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    const abi = await fetch("js/aedABI.json").then(r => r.json());
    AED = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);
    const address = await signer.getAddress();
    document.getElementById("wallet").innerText = "Wallet: " + address;
    console.log("✅ Connected:", address);
    await loadDomains(address);
  } catch (e) {
    console.error("Connection failed:", e);
  }
}

async function loadDomains(address) {
  const container = document.getElementById("domainList");
  container.innerHTML = "<p>Loading your domains...</p>";
  const count = await AED.balanceOf(address);
  if (count.toNumber() === 0) {
    container.innerHTML = "<p>No domains found.</p>";
    return;
  }

  container.innerHTML = "";
  for (let i = 0; i < count; i++) {
    const tokenId = await AED.tokenOfOwnerByIndex(address, i);
    const uri = await AED.tokenURI(tokenId);
    const metadata = await fetch(uri).then(r => r.json());
    const div = document.createElement("div");
    div.className = "domain-card";
    div.innerHTML = `
      <h3>${metadata.name}</h3>
      <img src="${metadata.image}" width="200"><br>
      <p>${metadata.description || ""}</p>
      <p><strong>Token ID:</strong> ${tokenId}</p>
    `;
    container.appendChild(div);
  }
}
