// Modular Header Component JavaScript

// Global variables for wallet and navigation
let provider = null;
let signer = null;
let userAddress = null;

// Admin wallet addresses (in production, this should be more secure)
const ADMIN_ADDRESSES = [
    '0x1234567890123456789012345678901234567890', // Example admin address
    '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd', // Another admin address
    // Add more admin addresses as needed
];

// Initialize header functionality
function initializeHeader() {
    setupHeaderEventListeners();
    checkWalletConnection();
}

// Setup all header event listeners
function setupHeaderEventListeners() {
    // Wallet connection events
    const connectBtn = document.getElementById('connectBtn');
    const disconnectBtn = document.getElementById('disconnectBtn');
    
    if (connectBtn) {
        connectBtn.addEventListener('click', connectWallet);
    }
    
    if (disconnectBtn) {
        disconnectBtn.addEventListener('click', disconnectWallet);
    }

    // Mobile menu events
    const hamburgerBtn = document.getElementById('hamburgerBtn');
    const navClose = document.getElementById('navClose');
    const navOverlay = document.getElementById('navOverlay');
    
    if (hamburgerBtn) {
        hamburgerBtn.addEventListener('click', toggleMobileMenu);
    }
    
    if (navClose) {
        navClose.addEventListener('click', closeMobileMenu);
    }
    
    if (navOverlay) {
        navOverlay.addEventListener('click', closeMobileMenu);
    }

    // Close menu on escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeMobileMenu();
        }
    });

    // Close menu when clicking nav links
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            // Small delay to allow navigation
            setTimeout(closeMobileMenu, 100);
        });
    });
}

// Mobile menu functions
function toggleMobileMenu() {
    const navMenu = document.getElementById('navMenu');
    const hamburgerBtn = document.getElementById('hamburgerBtn');
    
    if (navMenu && hamburgerBtn) {
        const isActive = navMenu.classList.contains('active');
        
        if (isActive) {
            closeMobileMenu();
        } else {
            openMobileMenu();
        }
    }
}

function openMobileMenu() {
    const navMenu = document.getElementById('navMenu');
    const hamburgerBtn = document.getElementById('hamburgerBtn');
    
    if (navMenu && hamburgerBtn) {
        navMenu.classList.add('active');
        hamburgerBtn.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function closeMobileMenu() {
    const navMenu = document.getElementById('navMenu');
    const hamburgerBtn = document.getElementById('hamburgerBtn');
    
    if (navMenu && hamburgerBtn) {
        navMenu.classList.remove('active');
        hamburgerBtn.classList.remove('active');
        document.body.style.overflow = '';
    }
}

// Wallet connection functions
async function connectWallet() {
    if (typeof window.ethereum !== 'undefined') {
        try {
            await window.ethereum.request({ method: 'eth_requestAccounts' });
            provider = new ethers.providers.Web3Provider(window.ethereum);
            signer = provider.getSigner();
            userAddress = await signer.getAddress();
            
            updateWalletDisplay(userAddress);
            checkAdminAccess(userAddress);
            
            // Trigger custom event for wallet connection
            window.dispatchEvent(new CustomEvent('walletConnected', { 
                detail: { address: userAddress } 
            }));
            
            console.log('Wallet connected:', userAddress);
        } catch (error) {
            console.error('Failed to connect wallet:', error);
            showNotification('Failed to connect wallet', 'error');
        }
    } else {
        showNotification('Please install MetaMask!', 'warning');
    }
}

async function disconnectWallet() {
    provider = null;
    signer = null;
    userAddress = null;
    
    updateWalletDisplay(null);
    hideAdminAccess();
    
    // Trigger custom event for wallet disconnection
    window.dispatchEvent(new CustomEvent('walletDisconnected'));
    
    console.log('Wallet disconnected');
}

// Update wallet display
function updateWalletDisplay(address) {
    const connectBtn = document.getElementById('connectBtn');
    const walletStatus = document.getElementById('walletStatus');
    const walletAddress = document.getElementById('walletAddress');
    
    if (address && connectBtn && walletStatus && walletAddress) {
        // Show connected state
        connectBtn.style.display = 'none';
        walletStatus.style.display = 'flex';
        walletAddress.textContent = `${address.slice(0, 6)}...${address.slice(-4)}`;
    } else if (connectBtn && walletStatus) {
        // Show disconnected state
        connectBtn.style.display = 'block';
        walletStatus.style.display = 'none';
    }
}

// Admin access control
function checkAdminAccess(address) {
    const adminLink = document.getElementById('adminLink');
    
    if (adminLink && address) {
        const isAdmin = ADMIN_ADDRESSES.includes(address.toLowerCase()) || 
                       ADMIN_ADDRESSES.includes(address);
        
        if (isAdmin) {
            adminLink.style.display = 'block';
            console.log('Admin access granted');
        } else {
            adminLink.style.display = 'none';
        }
    }
}

function hideAdminAccess() {
    const adminLink = document.getElementById('adminLink');
    if (adminLink) {
        adminLink.style.display = 'none';
    }
}

// Check for existing wallet connection
async function checkWalletConnection() {
    if (typeof window.ethereum !== 'undefined') {
        try {
            const accounts = await window.ethereum.request({ method: 'eth_accounts' });
            if (accounts.length > 0) {
                provider = new ethers.providers.Web3Provider(window.ethereum);
                signer = provider.getSigner();
                userAddress = accounts[0];
                
                updateWalletDisplay(userAddress);
                checkAdminAccess(userAddress);
                
                // Trigger custom event for existing connection
                window.dispatchEvent(new CustomEvent('walletConnected', { 
                    detail: { address: userAddress } 
                }));
            }
        } catch (error) {
            console.error('Error checking wallet connection:', error);
        }
    }
}

// Utility function for notifications
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    // Style the notification
    Object.assign(notification.style, {
        position: 'fixed',
        top: '20px',
        right: '20px',
        padding: '1rem 1.5rem',
        borderRadius: '8px',
        color: '#fff',
        fontFamily: 'Rajdhani, sans-serif',
        fontWeight: '600',
        zIndex: '10000',
        transform: 'translateX(100%)',
        transition: 'transform 0.3s ease',
        maxWidth: '300px',
        wordWrap: 'break-word'
    });
    
    // Set background color based on type
    switch (type) {
        case 'error':
            notification.style.background = 'linear-gradient(135deg, #ff6b6b, #ff5252)';
            break;
        case 'warning':
            notification.style.background = 'linear-gradient(135deg, #ffa726, #ff9800)';
            break;
        case 'success':
            notification.style.background = 'linear-gradient(135deg, #39FF14, #4eff28)';
            notification.style.color = '#000';
            break;
        default:
            notification.style.background = 'linear-gradient(135deg, #2196f3, #1976d2)';
    }
    
    // Add to page
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Remove after delay
    setTimeout(() => {
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 3000);
}

// Export functions for external use
window.HeaderModule = {
    initializeHeader,
    connectWallet,
    disconnectWallet,
    updateWalletDisplay,
    checkAdminAccess,
    showNotification,
    toggleMobileMenu,
    closeMobileMenu,
    // Getters for current state
    get provider() { return provider; },
    get signer() { return signer; },
    get userAddress() { return userAddress; },
    get isConnected() { return !!userAddress; }
};

// Auto-initialize when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeHeader);
} else {
    initializeHeader();
}
