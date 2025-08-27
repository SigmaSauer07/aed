// Modular Component Loader for AED Frontend

class ComponentLoader {
    constructor() {
        this.loadedComponents = new Set();
        this.componentCache = new Map();
    }

    // Load HTML component into target element
    async loadComponent(componentPath, targetSelector, options = {}) {
        try {
            const target = document.querySelector(targetSelector);
            if (!target) {
                throw new Error(`Target element not found: ${targetSelector}`);
            }

            // Check cache first
            let html;
            if (this.componentCache.has(componentPath)) {
                html = this.componentCache.get(componentPath);
            } else {
                const response = await fetch(componentPath);
                if (!response.ok) {
                    throw new Error(`Failed to load component: ${response.statusText}`);
                }
                html = await response.text();
                this.componentCache.set(componentPath, html);
            }

            // Process template variables if provided
            if (options.variables) {
                html = this.processTemplate(html, options.variables);
            }

            // Insert HTML
            if (options.append) {
                target.insertAdjacentHTML('beforeend', html);
            } else {
                target.innerHTML = html;
            }

            this.loadedComponents.add(componentPath);
            
            // Trigger custom event
            window.dispatchEvent(new CustomEvent('componentLoaded', {
                detail: { path: componentPath, target: targetSelector }
            }));

            return true;
        } catch (error) {
            console.error('Error loading component:', error);
            return false;
        }
    }

    // Load CSS file
    async loadCSS(cssPath) {
        return new Promise((resolve, reject) => {
            // Check if already loaded
            const existingLink = document.querySelector(`link[href="${cssPath}"]`);
            if (existingLink) {
                resolve(true);
                return;
            }

            const link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = cssPath;
            
            link.onload = () => resolve(true);
            link.onerror = () => reject(new Error(`Failed to load CSS: ${cssPath}`));
            
            document.head.appendChild(link);
        });
    }

    // Load JavaScript file
    async loadJS(jsPath) {
        return new Promise((resolve, reject) => {
            // Check if already loaded
            const existingScript = document.querySelector(`script[src="${jsPath}"]`);
            if (existingScript) {
                resolve(true);
                return;
            }

            const script = document.createElement('script');
            script.src = jsPath;
            script.type = 'text/javascript';
            
            script.onload = () => resolve(true);
            script.onerror = () => reject(new Error(`Failed to load JS: ${jsPath}`));
            
            document.head.appendChild(script);
        });
    }

    // Load complete component with HTML, CSS, and JS
    async loadFullComponent(componentName, targetSelector, options = {}) {
        const basePath = options.basePath || '../components/';
        
        try {
            // Load CSS first
            await this.loadCSS(`${basePath}${componentName}.css`);
            
            // Load HTML
            await this.loadComponent(`${basePath}${componentName}.html`, targetSelector, options);
            
            // Load JS last
            await this.loadJS(`${basePath}${componentName}.js`);
            
            console.log(`Component '${componentName}' loaded successfully`);
            return true;
        } catch (error) {
            console.error(`Error loading full component '${componentName}':`, error);
            return false;
        }
    }

    // Process template variables in HTML
    processTemplate(html, variables) {
        let processedHtml = html;
        
        Object.keys(variables).forEach(key => {
            const regex = new RegExp(`{{${key}}}`, 'g');
            processedHtml = processedHtml.replace(regex, variables[key]);
        });
        
        return processedHtml;
    }

    // Load header component
    async loadHeader(targetSelector = 'header', options = {}) {
        const defaultOptions = {
            basePath: '../components/',
            variables: {
                siteName: 'AED',
                ...options.variables
            }
        };
        
        return await this.loadFullComponent('header', targetSelector, defaultOptions);
    }

    // Load footer component
    async loadFooter(targetSelector = 'footer', options = {}) {
        const defaultOptions = {
            basePath: '../components/',
            variables: {
                year: new Date().getFullYear(),
                version: 'v1.0.0',
                ...options.variables
            }
        };
        
        return await this.loadFullComponent('footer', targetSelector, defaultOptions);
    }

    // Initialize common components
    async initializeCommonComponents(options = {}) {
        const results = {};
        
        try {
            // Load header if target exists
            const headerTarget = document.querySelector(options.headerTarget || 'header');
            if (headerTarget) {
                results.header = await this.loadHeader(options.headerTarget || 'header', options.headerOptions);
            }
            
            // Load footer if target exists
            const footerTarget = document.querySelector(options.footerTarget || 'footer');
            if (footerTarget) {
                results.footer = await this.loadFooter(options.footerTarget || 'footer', options.footerOptions);
            }
            
            console.log('Common components initialized:', results);
            return results;
        } catch (error) {
            console.error('Error initializing common components:', error);
            return results;
        }
    }

    // Clear component cache
    clearCache() {
        this.componentCache.clear();
        this.loadedComponents.clear();
    }

    // Get loaded components
    getLoadedComponents() {
        return Array.from(this.loadedComponents);
    }
}

// Create global instance
window.ComponentLoader = new ComponentLoader();

// Auto-initialize common components when DOM is ready
document.addEventListener('DOMContentLoaded', async () => {
    // Check for data attributes to auto-load components
    const autoLoadHeader = document.querySelector('[data-auto-load-header]');
    const autoLoadFooter = document.querySelector('[data-auto-load-footer]');
    
    if (autoLoadHeader || autoLoadFooter) {
        await window.ComponentLoader.initializeCommonComponents({
            headerTarget: autoLoadHeader ? autoLoadHeader.tagName.toLowerCase() : null,
            footerTarget: autoLoadFooter ? autoLoadFooter.tagName.toLowerCase() : null
        });
    }
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ComponentLoader;
}
