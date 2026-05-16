/** @type {import('next').NextConfig} */
const nextConfig = {
  outputFileTracing: false,
  basePath: '/calculator',
  output: 'export',
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || '',
  },
};
export default nextConfig;
