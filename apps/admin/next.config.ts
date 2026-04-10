import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: "https://api.trackeo.zenkai.mg/:path*",
      },
    ];
  },
};

export default nextConfig;