import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

const ALGORITHM = "aes-256-gcm";
const IV_BYTES = 12; // recommended IV size for GCM
const KEY_BYTES = 32; // AES-256
const FORMAT_VERSION = "v1";

/** Reads TOKEN_ENCRYPTION_KEY (base64) and checks that it is exactly 32 bytes. */
function loadKey(): Buffer {
  const raw = process.env.TOKEN_ENCRYPTION_KEY;
  if (!raw) {
    throw new Error("TOKEN_ENCRYPTION_KEY is missing. Generate one with: openssl rand -base64 32");
  }

  const key = Buffer.from(raw, "base64");
  if (key.length !== KEY_BYTES) {
    throw new Error(
      `TOKEN_ENCRYPTION_KEY must decode to ${KEY_BYTES} bytes (got ${key.length}). Generate one with: openssl rand -base64 32`,
    );
  }
  return key;
}

/**
 * Encrypts a secret (for example an OAuth or API token) with AES-256-GCM.
 * A fresh random IV is used every time, so the same input never gives the same output.
 * @returns A string like "v1:<iv>:<authTag>:<ciphertext>" (each part base64).
 */
export function encryptSecret(plaintext: string): string {
  const iv = randomBytes(IV_BYTES);
  const cipher = createCipheriv(ALGORITHM, loadKey(), iv);
  const ciphertext = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  const authTag = cipher.getAuthTag();

  return [
    FORMAT_VERSION,
    iv.toString("base64"),
    authTag.toString("base64"),
    ciphertext.toString("base64"),
  ].join(":");
}

/**
 * Decrypts a string produced by {@link encryptSecret}.
 * @throws If the format is wrong, the key is wrong, or the data was tampered with.
 */
export function decryptSecret(payload: string): string {
  const parts = payload.split(":");
  const [version, ivB64, tagB64, dataB64] = parts;

  if (parts.length !== 4 || version !== FORMAT_VERSION || !ivB64 || !tagB64 || !dataB64) {
    throw new Error("Encrypted value has an unknown format.");
  }

  try {
    const decipher = createDecipheriv(ALGORITHM, loadKey(), Buffer.from(ivB64, "base64"));
    decipher.setAuthTag(Buffer.from(tagB64, "base64"));
    const plaintext = Buffer.concat([
      decipher.update(Buffer.from(dataB64, "base64")),
      decipher.final(),
    ]);
    return plaintext.toString("utf8");
  } catch {
    // GCM fails here when the key is wrong or the stored value was modified.
    throw new Error("Could not decrypt value. Is TOKEN_ENCRYPTION_KEY the same key used to encrypt it?");
  }
}
