/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  async rewrites() {
    // Proxy /api/backend/* → backend service (useful for server-side calls in Docker)
    return [];
  },
};

export default nextConfig;
