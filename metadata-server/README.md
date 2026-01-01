# AED Metadata Server

A Next.js-powered dynamic metadata server for AED (Alsania Enhanced Domains) NFTs with Vercel Speed Insights integration.

## Features

- 🚀 Built with Next.js 15 for optimal performance
- ⚡ Vercel Speed Insights integration for real-time performance monitoring
- 🔗 Dynamic metadata generation from blockchain data
- 🎨 Modern, responsive UI with dark theme
- 📊 Evolution level and fragment tracking
- 🔄 Support for domains and subdomains
- 🖼️ Automatic image fallbacks
- ⚙️ Optimized for Vercel serverless deployment

## Tech Stack

- **Framework:** Next.js 15 (App Router)
- **Language:** TypeScript
- **Blockchain:** Ethers.js v6
- **Monitoring:** Vercel Speed Insights
- **Deployment:** Vercel

## API Endpoints

- `GET /api/domain/[tokenId]` - Get metadata for a domain NFT
- `GET /api/sub/[tokenId]` - Get metadata for a subdomain NFT
- `GET /api/debug` - Check environment configuration
- `GET /api/test-contract` - Test contract connectivity

## Getting Started

### Prerequisites

- Node.js 18.0.0 or higher
- npm or yarn
- Polygon Amoy RPC URL (from Alchemy, Infura, etc.)
- AED contract address

### Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env.local
   ```
   
   Edit `.env.local` and add:
   ```env
   AMOY_RPC=your_polygon_amoy_rpc_url
   CONTRACT_ADDRESS=your_aed_contract_address
   ```

3. **Run development server:**
   ```bash
   npm run dev
   ```

   Open [http://localhost:3000](http://localhost:3000) to view the app.

### Build for Production

```bash
npm run build
npm start
```

## Deployment to Vercel

### Quick Deploy

1. **Push to GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin your-repo-url
   git push -u origin main
   ```

2. **Deploy to Vercel:**
   - Go to [vercel.com](https://vercel.com)
   - Click "Import Project"
   - Select your repository
   - Vercel will auto-detect Next.js configuration

3. **Set Environment Variables:**
   In Vercel dashboard, add:
   - `AMOY_RPC`: Your Polygon Amoy RPC URL
   - `CONTRACT_ADDRESS`: Your AED contract address

4. **Deploy:**
   - Click "Deploy"
   - Your app will be live at `https://your-project.vercel.app`

### Deploy from Subfolder

If deploying from the `metadata-server/` subfolder:
- Set **Root Directory** to `metadata-server` in Vercel settings

## Environment Variables Required

| Variable | Description | Example |
|----------|-------------|---------|
| `AMOY_RPC` or `RPC_URL` | Polygon Amoy RPC URL | `https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY` |
| `CONTRACT_ADDRESS` | AED proxy address | `0x6452DCd7Bbee694223D743f09FF07c717Eeb34DF` |

## Speed Insights

Vercel Speed Insights is automatically integrated via the root layout. It provides:
- Real User Monitoring (RUM)
- Core Web Vitals tracking
- Performance analytics in Vercel dashboard

No additional configuration needed - it works out of the box!

## Project Structure

```
metadata-server/
├── app/
│   ├── api/
│   │   ├── domain/[tokenId]/route.ts
│   │   ├── sub/[tokenId]/route.ts
│   │   ├── debug/route.ts
│   │   └── test-contract/route.ts
│   ├── layout.tsx (includes Speed Insights)
│   ├── page.tsx
│   └── globals.css
├── lib/
│   ├── contract.ts
│   └── metadata.ts
├── next.config.js
├── tsconfig.json
└── package.json
```

## Legacy Express Server

The original Express-based server (`metadata-server.js`) is preserved and can be run with:
```bash
npm run legacy:dev
```

## Monitoring Performance

After deployment, view Speed Insights in your Vercel dashboard:
1. Go to your project in Vercel
2. Click "Speed Insights" tab
3. View real-time performance metrics

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `AMOY_RPC` | Polygon Amoy RPC URL | Yes |
| `CONTRACT_ADDRESS` | AED contract address | Yes |

## License

Part of the Alsania Enhanced Domains project.