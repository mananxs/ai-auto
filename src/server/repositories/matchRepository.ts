import { prisma } from "@/server/db";

/** One scored candidate, ready to render as a match card. */
export interface MatchRow {
  matchId: string;
  score: number;
  matchedSkills: string[];
  missingSkills: string[];
  model: string | null;
  candidateId: string;
  githubId: bigint;
  login: string;
  name: string | null;
  avatarUrl: string | null;
  profileUrl: string;
  bio: string | null;
  location: string | null;
}

export interface ListMatchesParams {
  jobId: string;
  minScore: number;
  limit: number;
  offset: number;
}

/**
 * Returns completed matches for a job, best score first, in ONE joined query.
 * The (jobId, score DESC) index serves the WHERE + ORDER BY.
 */
export async function listCompletedMatches(params: ListMatchesParams): Promise<MatchRow[]> {
  const { jobId, minScore, limit, offset } = params;

  return prisma.$queryRaw<MatchRow[]>`
    SELECT
      m."id" AS "matchId",
      m."score",
      m."matchedSkills",
      m."missingSkills",
      m."model",
      c."id" AS "candidateId",
      c."githubId",
      c."login",
      c."name",
      c."avatarUrl",
      c."profileUrl",
      c."bio",
      c."location"
    FROM match_scores m
    JOIN candidates c ON c."id" = m."candidateId"
    WHERE m."jobId" = ${jobId}::uuid
      AND m."status" = 'completed'
      AND m."score" >= ${minScore}
    ORDER BY m."score" DESC, m."id" ASC
    LIMIT ${limit} OFFSET ${offset}
  `;
}
