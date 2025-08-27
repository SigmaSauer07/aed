# AED Metadata Server

This is a dynamic metadata server for AED (Alsania Enhanced Domains) NFTs. It serves metadata for domains and subdomains by reading data directly from the blockchain.

## Features

- Dynamic metadata generation based on on-chain data
- Supports both domains and subdomains
- Automatic image fallback to default backgrounds
- Structured attributes for NFT marketplaces

## API Endpoints

- `GET /domain/:tokenId.json` - Get metadata for a domain NFT
- `GET /sub/:tokenId.json` - Get metadata for a subdomain NFT
- `GET /` - Health check endpoint

## Local Development

1. **Install dependencies:**
   ```bash
   cd metadata-server
   npm install
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your actual values:
   - `AMOY_RPC`: Your Polygon Amoy RPC URL (get from Alchemy, Infura, etc.)
   - `CONTRACT_ADDRESS`: Your AED contract address
   - `PORT`: Port for local server (optional, defaults to 3000)

3. **Run the server:**
   ```bash
   npm run dev
   ```

4. **Test the endpoints:**
   - Visit `http://localhost:3000/` for health check
   - Visit `http://localhost:3000/domain/1.json` to test domain metadata

## Deployment to Vercel

### Step 1: Prepare Your Git Repository

This project is already set up in the `metadata-server/` subfolder. For Vercel deployment, you have a few options:

**Option A: Deploy from subfolder (Recommended)**
- Push your entire AED project to GitHub
- Vercel will detect the subfolder automatically

**Option B: Create separate repository**
- Copy the `metadata-server/` folder contents to a new Git repository
- Deploy from the root of that repository

### Step 2: Deploy to Vercel

1. **Sign up/Login to Vercel:**
   - Go to [vercel.com](https://vercel.com)
   - Sign up or log in with your GitHub account

2. **Import your project:**
   - Click "Import Project"
   - Connect your GitHub account
   - Select your repository

3. **Configure the project:**
   - **Root Directory:** Enter `metadata-server` (if deploying from subfolder)
   - **Build Command:** Leave empty (Vercel will use the one from package.json)
   - **Output Directory:** Leave empty
   - **Install Command:** `npm install`

4. **Set Environment Variables:**
   In the Vercel dashboard, go to your project settings and add:
   - `AMOY_RPC`: Your Polygon Amoy RPC URL
   - `CONTRACT_ADDRESS`: Your AED contract address

5. **Deploy:**
   - Click "Deploy"
   - Vercel will build and deploy your server

### Step 3: Get Your Deployment URL

After deployment, Vercel will give you a URL like:
`https://your-project-name.vercel.app`

Your metadata endpoints will be:
- `https://your-project-name.vercel.app/domain/:tokenId.json`
- `https://your-project-name.vercel.app/sub/:tokenId.json`

## Updating Your Smart Contract

To update the metadata server after making changes:

1. Make your changes to the code
2. Commit and push to your Git repository
3. Vercel will automatically redeploy (if auto-deployment is enabled)
4. Or manually trigger a deployment in the Vercel dashboard

## Troubleshooting

- **Error: "Missing RPC_URL/CONTRACT_ADDRESS"**
  - Make sure your environment variables are set correctly
  - For local development: Check your `.env` file
  - For Vercel: Check environment variables in project settings

- **Error: "failed" response from API**
  - Check the server logs in Vercel dashboard
  - Verify your RPC URL is working
  - Verify your contract address is correct

- **Slow responses**
  - This is normal for on-chain data reading
  - Consider implementing caching if needed for production

## Environment Variables Reference

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `AMOY_RPC` | Polygon Amoy RPC URL | Yes | `https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY` |
| `CONTRACT_ADDRESS` | AED contract address | Yes | `0xd0E5EB4C244d0e641ee10EAd309D3F6DC627F63E` |
| `PORT` | Local development port | No | `3000` |