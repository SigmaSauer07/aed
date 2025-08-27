// ai-chat.js
// Simple AI chat widget for Alsania. This component can be embedded on any
// page by including the CSS and JS files and calling initAIChat().

function initAIChat(options = {}) {
    const defaultOptions = {
        title: options.title || 'Alsania AI',
        placeholder: options.placeholder || 'Ask me anything…',
        welcomeMessage: options.welcomeMessage || 'Hello! How can I assist you today?',
        // Provide your own async function to call an AI backend.
        async onAsk(message) {
            // TODO: replace this stub with an API call to your AI service
            return 'This is a stubbed response. Integrate your AI backend here.';
        },
    };
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
    titleEl.textContent = defaultOptions.title;
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
    input.placeholder = defaultOptions.placeholder;
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
    addMessage(defaultOptions.welcomeMessage, 'ai');

    async function handleSend() {
        const text = input.value.trim();
        if (!text) return;
        addMessage(text, 'user');
        input.value = '';
        // Call AI backend
        try {
            const response = await defaultOptions.onAsk(text);
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