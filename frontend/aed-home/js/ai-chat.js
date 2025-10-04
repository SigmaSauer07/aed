// ai-chat.js
// Simple AI chat widget for Alsania. This component can be embedded on any
// page by including the CSS and JS files and calling initAIChat().

function initAIChat(options = {}) {
    const config = {
        title: options.title || 'Alsania AI',
        placeholder: options.placeholder || 'Ask me anything…',
        welcomeMessage: options.welcomeMessage || 'Hello! How can I assist you today?',
        endpoint: options.endpoint || null,
        docsUrl: options.docsUrl || 'https://alsania.gitbook.io/aed',
        apiHeaders: options.apiHeaders || {},
        onAsk: options.onAsk,
    };

    const askHandler = typeof config.onAsk === 'function'
        ? config.onAsk
        : createDefaultAskHandler(config);
    // Create toggle button
    const toggleBtn = document.createElement('button');
    toggleBtn.className = 'ai-chat-toggle';
    toggleBtn.innerHTML = '💬';
    document.body.appendChild(toggleBtn);

    // Create chat widget container
    const widget = document.createElement('div');
    widget.className = 'ai-chat-widget';
    widget.style.display = 'none';

    // Header
    const header = document.createElement('div');
    header.className = 'ai-chat-header';
    const titleEl = document.createElement('h4');
    titleEl.textContent = config.title;
    const closeBtn = document.createElement('button');
    closeBtn.textContent = '×';
    closeBtn.style.background = 'none';
    closeBtn.style.border = 'none';
    closeBtn.style.color = '#dcdcdc';
    closeBtn.style.fontSize = '1.25rem';
    closeBtn.style.cursor = 'pointer';
    header.appendChild(titleEl);
    header.appendChild(closeBtn);
    widget.appendChild(header);

    // Messages container
    const messages = document.createElement('div');
    messages.className = 'ai-chat-messages';
    widget.appendChild(messages);

    // Input area
    const inputArea = document.createElement('div');
    inputArea.className = 'ai-chat-input';
    const input = document.createElement('input');
    input.type = 'text';
    input.placeholder = config.placeholder;
    const sendBtn = document.createElement('button');
    sendBtn.textContent = 'Send';
    inputArea.appendChild(input);
    inputArea.appendChild(sendBtn);
    widget.appendChild(inputArea);

    document.body.appendChild(widget);

    function addMessage(text, type = 'user') {
        const msg = document.createElement('div');
        msg.className = `ai-chat-message ${type}`;
        msg.textContent = text;
        messages.appendChild(msg);
        messages.scrollTop = messages.scrollHeight;
    }

    // Show welcome message
    addMessage(config.welcomeMessage, 'ai');

    async function handleSend() {
        const text = input.value.trim();
        if (!text) return;
        addMessage(text, 'user');
        input.value = '';
        // Call AI backend
        try {
            const response = await askHandler(text);
            addMessage(response, 'ai');
        } catch (err) {
            console.error(err);
            addMessage('Sorry, there was an error processing your request.', 'ai');
        }
    }
    sendBtn.addEventListener('click', handleSend);
    input.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            handleSend();
        }
    });

    toggleBtn.addEventListener('click', () => {
        const isVisible = widget.style.display === 'block';
        widget.style.display = isVisible ? 'none' : 'flex';
    });
    closeBtn.addEventListener('click', () => {
        widget.style.display = 'none';
    });
}

function createDefaultAskHandler(config) {
    const faq = [
        {
            keywords: ['price', 'cost', 'fee'],
            response: 'Domain pricing: free for .aed/.alsa/.07, 1 MATIC for .alsania/.fx/.echo. Subdomain enhancement is 2 MATIC. The exact gas estimate is shown before each transaction.',
        },
        {
            keywords: ['deploy', 'upgrade', 'contract'],
            response: 'Contracts are UUPS upgradeable. Use Hardhat: `npx hardhat compile`, `npx hardhat test`, then `npx hardhat run scripts/deploy.js --network amoy`. Remember to verify via `npx hardhat verify`. Full docs: ' + config.docsUrl,
        },
        {
            keywords: ['support', 'help', 'contact'],
            response: 'Ping the Alsania core team in the Sovereign Builders channel or email support@alsania.io. We respond within 24 hours.',
        },
        {
            keywords: ['feature', 'roadmap', 'coming'],
            response: 'Upcoming features: cross-chain bridging, enhancement marketplace, and profile badges. Follow updates at ' + config.docsUrl + '.',
        },
    ];

    return async function defaultAsk(message) {
        const trimmed = message.trim();
        if (config.endpoint) {
            const response = await fetch(config.endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...config.apiHeaders,
                },
                body: JSON.stringify({ message: trimmed }),
            });

            if (!response.ok) {
                throw new Error(`AI endpoint error: ${response.status}`);
            }

            const data = await response.json();
            if (typeof data.answer === 'string') {
                return data.answer;
            }
            if (Array.isArray(data.messages) && data.messages.length > 0) {
                return data.messages[data.messages.length - 1];
            }
            return JSON.stringify(data);
        }

        const lower = trimmed.toLowerCase();
        for (const entry of faq) {
            if (entry.keywords.some((keyword) => lower.includes(keyword))) {
                return entry.response;
            }
        }

        return `Alsania AI here. I could not match that question, but the deployment and integration manuals live at ${config.docsUrl}.`;
    };
}
