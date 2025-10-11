# AED Metadata Server

This is a dynamic metadata server for AED (Alsania Enhanced Domains) NFTs. It serves metadata for domains and subdomains by reading data directly from the blockchain.

## Features

- Dynamic metadata generation based on on-chain data
- Supports both domains and subdomains
- Automatic image fallback to default backgrounds
- Includes global admin-set description in all metadata
- Optimized for Vercel serverless deployment

## API Endpoints

- `GET /domain/:tokenId.json` - Get metadata for a domain NFT
- `GET /sub/:tokenId.json` - Get metadata for a subdomain NFT
- `GET /` - Health check endpoint

## Deployment to Vercel

### Step 1: Prepare the Repository

1. **Create a separate repository** (recommended):
   ```bash
   # Option A: Create new repo and copy metadata-server folder
   mkdir aed-metadata-server
   cd aed-metadata-server
   git init

   # Copy metadata-server contents
   cp -r ../your-main-repo/metadata-server/* ./
   ```

2. **Or deploy from subfolder** (alternative):
   - Push your entire AED project to GitHub
   - Vercel can deploy from the `metadata-server/` subfolder

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
   - `AMOY_RPC`: Your Polygon Amoy RPC URL (get from Alchemy, Infura, etc.)
   - `CONTRACT_ADDRESS`: Your AED contract address

5. **Deploy:**
   - Click "Deploy"
   - Vercel will build and deploy your server

### Step 3: Get Your Deployment URL

After deployment, Vercel will give you a URL like:
`https://your-project-name.vercel.app`

Your metadata endpoints will be:
- `https://your-project-name.vercel.app/domain/1.json`
- `https://your-project-name.vercel.app/sub/1.json`

## Environment Variables Required

| Variable | Description | Example |
|----------|-------------|---------|
| `AMOY_RPC` or `RPC_URL` | Polygon Amoy RPC URL | `https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY` |
| `CONTRACT_ADDRESS` | AED proxy address | `0x6452DCd7Bbee694223D743f09FF07c717Eeb34DF` |

## Local Development

```bash
cd metadata-server
npm install
npm run dev
```

Visit `http://localhost:3000/` for health check.

## Updating Your Smart Contract

To update the metadata server after making changes:

1. Make your changes to the code
2. Commit and push to your Git repository
3. Vercel will automatically redeploy (if auto-deployment is enabled)
4. Or manually trigger a deployment in the Vercel dashboard

## Contract Integration

The server automatically reads:
- Domain/subdomain information from your AED contract
- Global description set by admins
- Custom images and profiles if set

## Error Handling

- Returns proper HTTP status codes
- Graceful fallbacks for missing data
- Console logging for debugging

## Performance Notes

- 30-second function timeout
- 1GB memory allocation
- Cache-control headers for metadata endpoints
- Regional deployment (Europe) for lower latency