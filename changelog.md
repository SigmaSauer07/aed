new aed‑frontend package that contains clean, modular pages for AEDHome and AEDAdmin. Each page uses a shared dark theme with neon‑green accents (#39FF14) and Orbitron/Inter fonts to match your sci‑fi aesthetic. Key highlights:

AEDHome: includes a responsive header with nav links and a wallet‑connect button, a hero section introducing Alsania Enhanced Domains, a features grid explaining domain registration, subdomains, on‑chain metadata and the modular architecture, and a domain registration form that validates .alsania names and shows a confirmation message. The page uses a simple JavaScript stub so you can later plug in your AEDMinting contract calls.

AEDAdmin: features dashboard cards for total domains, active subdomains, fees collected and platform status, plus forms to update platform fees and fee recipients, add new TLDs, and grant or revoke roles. Metrics are stubbed for now but ready to be replaced with live contract data. Role management and fee updates trigger alert messages to simulate transactions.

Wallet module: both pages import a reusable wallet.js component that connects to an injected Web3 provider (e.g. MetaMask), stores the connected address in localStorage and updates the wallet button label so users remain logged in across pages.

Styling: CSS files implement a modern grid layout, responsive design, hover effects, and imported Google fonts. The admin styles extend the base home styles with card layouts and form controls.

You can download the ready‑made frontend archive here: aed-frontend.zip Extract it into your project (or serve it separately) so frontend/AEDHome/index.html and frontend/AEDAdmin/index.html load correctly. To hook the pages up to your smart contracts, replace the placeholder comments in the JavaScript with actual calls to your AEDMinting and AEDAdmin modules using ethers.js or web3.js. Adjust the navigation paths, logo and background images as needed to integrate with your main Alsania site.
