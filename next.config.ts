import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // pino and pino-pretty use Node internals; keep them out of the bundler.
  serverExternalPackages: ["pino", "pino-pretty"],
};

export default nextConfig;
