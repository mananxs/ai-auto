import { prisma } from "@/server/db";
import { decryptSecret, encryptSecret } from "@/server/crypto/tokens";

export type TokenProvider = "github";

/**
 * Saves (or replaces) a recruiter's token. The plain token is encrypted before it touches the DB.
 */
export async function saveToken(
  recruiterId: string,
  provider: TokenProvider,
  plainToken: string,
): Promise<void> {
  const encryptedToken = encryptSecret(plainToken);

  await prisma.oAuthToken.upsert({
    where: { recruiterId_provider: { recruiterId, provider } },
    update: { encryptedToken },
    create: { recruiterId, provider, encryptedToken },
  });
}

/**
 * Loads and decrypts a recruiter's token (one query).
 * @returns The plain token, or null if the recruiter has not stored one.
 */
export async function getDecryptedToken(
  recruiterId: string,
  provider: TokenProvider,
): Promise<string | null> {
  const row = await prisma.oAuthToken.findUnique({
    where: { recruiterId_provider: { recruiterId, provider } },
    select: { encryptedToken: true },
  });

  return row ? decryptSecret(row.encryptedToken) : null;
}
