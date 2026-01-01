export default function Home() {
  return (
    <main className="container">
      <div className="content">
        <h1>AED Metadata Server</h1>
        <p className="subtitle">Alsania Enhanced Domains - Dynamic NFT Metadata</p>
        
        <div className="status">
          <span className="status-indicator"></span>
          <span>Server Online</span>
        </div>

        <div className="endpoints">
          <h2>API Endpoints</h2>
          <div className="endpoint-list">
            <div className="endpoint">
              <code>GET /api/domain/:tokenId</code>
              <p>Get metadata for a domain NFT</p>
            </div>
            <div className="endpoint">
              <code>GET /api/sub/:tokenId</code>
              <p>Get metadata for a subdomain NFT</p>
            </div>
            <div className="endpoint">
              <code>GET /api/debug</code>
              <p>Check environment configuration</p>
            </div>
            <div className="endpoint">
              <code>GET /api/test-contract</code>
              <p>Test contract connectivity</p>
            </div>
          </div>
        </div>

        <div className="info">
          <h3>Features</h3>
          <ul>
            <li>Dynamic metadata generation from blockchain</li>
            <li>Support for domains and subdomains</li>
            <li>Evolution level and fragment tracking</li>
            <li>Automatic image fallbacks</li>
            <li>Optimized for Vercel deployment</li>
          </ul>
        </div>
      </div>
    </main>
  );
}