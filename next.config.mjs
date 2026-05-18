/** @type {import('next').NextConfig} */
const nextConfig = {
  outputFileTracing: false,
  output: 'export',
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || '',
  },
};
export default nextConfig;
