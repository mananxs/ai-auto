import pino from "pino";
import pretty from "pino-pretty";

const isProduction = process.env.NODE_ENV === "production";

/**
 * App-wide structured logger.
 * - Production: plain JSON lines (easy to ship to any log tool).
 * - Development: human-readable colored output.
 * Secrets are redacted if they ever end up in a log object.
 */
export const logger = pino(
  {
    level: process.env.LOG_LEVEL ?? "info",
    base: { service: "talentgraph" },
    redact: {
      paths: [
        "token",
        "*.token",
        "encryptedToken",
        "*.encryptedToken",
        "authorization",
        "*.authorization",
        "apiKey",
        "*.apiKey",
      ],
      censor: "[redacted]",
    },
  },
  isProduction ? undefined : pretty({ colorize: true, translateTime: "HH:MM:ss", ignore: "pid,hostname,service" }),
);

/**
 * Creates a logger that adds `module` to every line.
 * @param module Short name of the calling module, e.g. "github-client".
 */
export function createLogger(module: string): pino.Logger {
  return logger.child({ module });
}
