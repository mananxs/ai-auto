import { NextResponse } from "next/server";
import { prisma } from "@/server/db";
import { createLogger } from "@/server/logger";

const log = createLogger("health");

// Always hit the database; never cache this response.
export const dynamic = "force-dynamic";

interface HealthRow {
  pgvectorVersion: string | null;
  jobs: number;
  recruiters: number;
}

/** GET /api/health - checks the DB connection, the pgvector extension and that the seed ran. */
export async function GET(): Promise<NextResponse> {
  try {
    const rows = await prisma.$queryRaw<HealthRow[]>`
      SELECT
        (SELECT extversion FROM pg_extension WHERE extname = 'vector') AS "pgvectorVersion",
        (SELECT COUNT(*)::int FROM job_descriptions) AS "jobs",
        (SELECT COUNT(*)::int FROM recruiters) AS "recruiters"
    `;
    const row = rows[0];

    return NextResponse.json({
      ok: true,
      database: "connected",
      pgvectorVersion: row?.pgvectorVersion ?? null,
      seeded: { jobs: row?.jobs ?? 0, recruiters: row?.recruiters ?? 0 },
    });
  } catch (error) {
    log.error({ err: error }, "health check failed");
    return NextResponse.json({ ok: false, database: "unreachable" }, { status: 503 });
  }
}
