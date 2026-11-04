import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z.string().min(1),
  DIRECT_URL: z.string().min(1),
  TOKEN_ENCRYPTION_KEY: z.string().min(1),
  GEMINI_API_KEY: z.string().min(1),
  LLM_MODEL: z.string().min(1).default("gemini-2.5-flash"),
  GITHUB_PAT: z.string().optional(),
  DEV_AUTH: z
    .enum(["true", "false"])
    .default("false")
    .transform((value) => value === "true"),
  DEV_RECRUITER_EMAIL: z.string().email().default("recruiter@talentgraph.dev"),
  EVAL_CONCURRENCY: z.coerce.number().int().min(1).max(10).default(2),
  LOG_LEVEL: z.enum(["fatal", "error", "warn", "info", "debug", "trace"]).default("info"),
});

export type Env = z.infer<typeof envSchema>;

let cachedEnv: Env | undefined;

/**
 * Reads and validates environment variables once.
 * Throws a readable error listing every missing/invalid variable.
 */
export function getEnv(): Env {
  if (cachedEnv) return cachedEnv;

  const result = envSchema.safeParse(process.env);
  if (!result.success) {
    const problems = result.error.issues
      .map((issue) => `  - ${issue.path.join(".")}: ${issue.message}`)
      .join("\n");
    throw new Error(`Invalid environment variables:\n${problems}`);
  }

  cachedEnv = result.data;
  return cachedEnv;
}
