document.getElementById("connectBtn").addEventListener("click", async () => {
  if (window.ethereum) {
    try {
      const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
      document.getElementById("walletStatus").textContent = `Wallet: ${accounts[0]}`;
    } catch (error) {
      document.getElementById("walletStatus").textContent = "Wallet: Connection failed";
      console.error("Connection Error:", error);
    }
  } else {
    document.getElementById("walletStatus").textContent = "Wallet: MetaMask not detected";
  }
});
