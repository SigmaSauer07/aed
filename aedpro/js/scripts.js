async function connectWallet() {
  if (!window.ethereum) {
    alert("Please install MetaMask or another Web3 wallet!");
    return;
  }
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  const signer = provider.getSigner();
  const address = await signer.getAddress();
  document.getElementById("walletAddress").innerText = address;
  document.getElementById("connectBtn")?.innerText = "Connected";
}

document.addEventListener('DOMContentLoaded', () => {
  const themeBtn = document.getElementById("themeToggle");
  themeBtn?.addEventListener('click', () => {
    document.body.classList.toggle("dark-mode");
  });

  // If on profile.html, fetch domain info and render
  if (window.location.pathname.includes('profile.html')) {
    const domain = new URLSearchParams(window.location.search).get('domain') || 'example.hub';
    document.getElementById('domainTitle').innerText = domain;
    // TODO: fetch actual bio, IPFS link from contract or backend
    document.getElementById('bio').innerText = 'Loading...';
    document.getElementById('ipfsLink').innerText = 'Loading...';
  }
});
