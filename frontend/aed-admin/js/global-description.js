// Global Description Component
class GlobalDescriptionManager {
    constructor() {
        this.contract = null;
        this.isLoading = false;
        this.init();
    }

    init() {
        this.bindEvents();
        this.loadCurrentDescription();
    }

    bindEvents() {
        const button = document.getElementById('set-global-description-btn');
        const textarea = document.getElementById('global-desc-input');

        if (button) {
            button.addEventListener('click', () => this.setGlobalDescription());
        }

        if (textarea) {
            textarea.addEventListener('input', () => this.updatePreview());
        }
    }

    async loadCurrentDescription() {
        if (!this.contract) {
            await this.initializeContract();
        }

        if (!this.contract) return;

        try {
            this.showStatus('Loading current description...', 'info');
            const description = await this.contract.getGlobalDescription();
            const textarea = document.getElementById('global-desc-input');
            if (textarea) {
                textarea.value = description || '';
                this.updatePreview();
            }
            this.clearStatus();
        } catch (error) {
            console.error('Error loading description:', error);
            this.showStatus('Failed to load current description', 'error');
        }
    }

    async setGlobalDescription() {
        if (this.isLoading) return;

        const description = document.getElementById('global-desc-input')?.value || '';

        if (!description.trim()) {
            this.showStatus('Please enter a description', 'error');
            return;
        }

        if (!this.contract) {
            await this.initializeContract();
        }

        if (!this.contract) {
            this.showStatus('Failed to connect to contract', 'error');
            return;
        }

        this.isLoading = true;
        this.setButtonLoading(true);

        try {
            this.showStatus('Updating global description...', 'info');

            const tx = await this.contract.setGlobalDescription(description);
            await tx.wait();

            this.showStatus('✅ Global description updated successfully!', 'success');

            // Reload the description to confirm
            setTimeout(() => {
                this.loadCurrentDescription();
            }, 2000);

        } catch (error) {
            console.error('Error updating description:', error);
            let errorMessage = 'Failed to update description';

            if (error.code === 4001) {
                errorMessage = 'Transaction cancelled by user';
            } else if (error.code === -32603) {
                errorMessage = 'Insufficient funds or network error';
            } else if (error.message.includes('reverted')) {
                errorMessage = 'Transaction reverted - check your permissions';
            }

            this.showStatus(errorMessage, 'error');
        } finally {
            this.isLoading = false;
            this.setButtonLoading(false);
        }
    }

    async initializeContract() {
        if (window.contract) {
            this.contract = window.contract;
        } else {
            this.showStatus('Please connect your wallet first', 'error');
            return false;
        }
        return true;
    }

    updatePreview() {
        const textarea = document.getElementById('global-desc-input');
        const preview = document.getElementById('description-preview');

        if (textarea && preview) {
            const text = textarea.value;
            preview.textContent = text || 'No description set';
        }
    }

    showStatus(message, type = 'info') {
        const statusElement = document.getElementById('global-description-status');
        if (statusElement) {
            statusElement.textContent = message;
            statusElement.className = `global-description-status ${type}`;
        }
    }

    clearStatus() {
        const statusElement = document.getElementById('global-description-status');
        if (statusElement) {
            statusElement.textContent = '';
            statusElement.className = 'global-description-status';
        }
    }

    setButtonLoading(loading) {
        const button = document.getElementById('set-global-description-btn');
        if (button) {
            button.disabled = loading;
            button.classList.toggle('loading', loading);

            if (loading) {
                button.innerHTML = '<div class="spinner"></div> Updating...';
            } else {
                button.innerHTML = 'Update Description';
            }
        }
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.globalDescriptionManager = new GlobalDescriptionManager();
});

// Export for global access
window.GlobalDescriptionManager = GlobalDescriptionManager;