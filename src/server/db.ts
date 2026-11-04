import { PrismaClient } from "@prisma/client";

// In dev, Next.js reloads modules often. Keeping one client on globalThis
// avoids opening a new connection pool on every reload.
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

/** Shared Prisma client. Import this instead of creating new PrismaClient() instances. */
export const prisma: PrismaClient =
  globalForPrisma.prisma ?? new PrismaClient({ log: ["warn", "error"] });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
