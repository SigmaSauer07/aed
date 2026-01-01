# Deployment Guide for AED Metadata Server

## Prerequisites

- GitHub account
- Vercel account (free tier works)
- Your environment variables ready:
  - `AMOY_RPC`: Polygon Amoy RPC URL
  - `CONTRACT_ADDRESS`: Your AED contract address

---

## Method 1: Vercel CLI (Recommended - Fastest)

### Step 1: Install Vercel CLI (if not already installed)
```bash
npm install -g vercel
```

### Step 2: Navigate to project
```bash
cd metadata-server
```

### Step 3: Deploy
```bash
npx vercel
```

Answer the prompts:
- **Set up and deploy?** → Yes
- **Which scope?** → Select your account
- **Link to existing project?** → No (first time) or Yes (subsequent deploys)
- **Project name?** → Press Enter (uses `aed-metadata`)
- **Directory?** → Press Enter (current directory)
- **Override settings?** → No

### Step 4: Add Environment Variables
```bash
# Add AMOY_RPC
npx vercel env add AMOY_RPC
# When prompted, paste your RPC URL

# Add CONTRACT_ADDRESS
npx vercel env add CONTRACT_ADDRESS
# When prompted, paste your contract address
```

### Step 5: Deploy to Production
```bash
npx vercel --prod
```

**Done!** Your app is live at the URL shown in terminal.

---

## Method 2: Vercel Dashboard (Visual Interface)

### Step 1: Push to GitHub
```bash
# If not already a git repo
git init
git add .
git commit -m "Initial Next.js metadata server"

# Create a repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### Step 2: Import to Vercel
1. Go to [vercel.com/new](https://vercel.com/new)
2. Click "Import Project"
3. Select your GitHub repository
4. **Important:** If your repo has the full AED project:
   - Click "Edit" next to Root Directory
   - Enter: `metadata-server`
   - Click "Continue"

### Step 3: Configure Build Settings
Vercel auto-detects Next.js, so just verify:
- **Framework Preset:** Next.js
- **Build Command:** `next build`
- **Output Directory:** `.next`
- **Install Command:** `npm install`

### Step 4: Add Environment Variables
Before clicking "Deploy", add environment variables:
1. Click "Environment Variables"
2. Add `AMOY_RPC`:
   - Name: `AMOY_RPC`
   - Value: Your Polygon Amoy RPC URL
   - Environment: Production, Preview, Development (select all)
3. Add `CONTRACT_ADDRESS`:
   - Name: `CONTRACT_ADDRESS`
   - Value: Your AED contract address
   - Environment: Production, Preview, Development (select all)

### Step 5: Deploy
Click "Deploy" and wait ~2 minutes.

**Done!** Your app is live at `https://your-project.vercel.app`

---

## After Deployment

### View Your App
Your metadata server will be available at:
- Homepage: `https://your-project.vercel.app`
- Domain metadata: `https://your-project.vercel.app/api/domain/1`
- Subdomain metadata: `https://your-project.vercel.app/api/sub/1`
- Debug endpoint: `https://your-project.vercel.app/api/debug`

### Check Speed Insights
1. Go to your Vercel dashboard
2. Select your project
3. Click "Speed Insights" tab
4. View real-time performance metrics

### Update Environment Variables (if needed)
**Via CLI:**
```bash
npx vercel env rm AMOY_RPC production
npx vercel env add AMOY_RPC production
```

**Via Dashboard:**
1. Go to project Settings → Environment Variables
2. Edit or delete existing variables
3. Redeploy from Deployments tab

---

## Troubleshooting

### Build Fails
- Check that all dependencies are in `package.json`
- Verify TypeScript has no errors: `npm run build` locally

### API Routes Return 500
- Verify environment variables are set correctly
- Check Vercel Function Logs in dashboard

### Speed Insights Not Showing
- Wait 24 hours for data to populate
- Ensure you're on a Vercel Pro plan (Speed Insights requires Pro)
- Free tier has limited analytics

---

## Continuous Deployment

Once connected to GitHub:
1. Push changes to your repository
2. Vercel automatically deploys
3. Preview deployments for branches
4. Production deployment for main branch

---

## Custom Domain (Optional)

1. Go to project Settings → Domains
2. Add your custom domain
3. Configure DNS records as shown
4. SSL certificate auto-generated

---

## Monitoring

- **Logs:** Vercel Dashboard → Your Project → Logs
- **Analytics:** Vercel Dashboard → Your Project → Analytics
- **Speed Insights:** Vercel Dashboard → Your Project → Speed Insights

---

## Need Help?

- Vercel Docs: https://vercel.com/docs
- Next.js Docs: https://nextjs.org/docs
- Vercel Support: https://vercel.com/support