/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  experimental: {
    serverActions: {
      bodySizeLimit: '2mb',
    },
  },
  allowedDevOrigins: ['192.168.1.14:3000'],
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'aqua-left-quelea-716.mypinata.cloud',
      },
    ],
  },
};

module.exports = nextConfig;