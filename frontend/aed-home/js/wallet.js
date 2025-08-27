// wallet.js
// This module handles connecting to MetaMask (or any injected Ethereum provider)
// and persists the connected account across page reloads using localStorage. When
// connected, it updates the wallet button text to show a truncated address.

async function connectWallet() {
    if (typeof window.ethereum === 'undefined') {
        alert('A Web3 wallet (e.g. MetaMask) is required to use this dApp.');
        return;
    }
    try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        if (accounts.length > 0) {
            const account = accounts[0];
            localStorage.setItem('aedConnectedAddress', account);
            updateWalletButton(account);
        }
    } catch (err) {
        console.error('Wallet connection failed:', err);
    }
}

function updateWalletButton(account) {
    const btn = document.getElementById('walletButton');
    if (!btn) return;
    if (account) {
        // Display first 6 and last 4 characters for brevity
        const truncated = account.slice(0, 6) + '…' + account.slice(-4);
        btn.textContent = truncated;
        btn.classList.add('connected');
    } else {
        btn.textContent = 'Connect Wallet';
        btn.classList.remove('connected');
    }
}

function checkWalletConnection() {
    const saved = localStorage.getItem('aedConnectedAddress');
    if (saved) {
        updateWalletButton(saved);
    }
}

// Bind event on wallet button
document.addEventListener('DOMContentLoaded', () => {
    const btn = document.getElementById('walletButton');
    if (btn) {
        btn.addEventListener('click', connectWallet);
    }
    checkWalletConnection();
});