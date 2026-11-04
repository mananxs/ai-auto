import type { Prisma } from "@prisma/client";
import { prisma } from "@/server/db";

const jobSelect = {
  id: true,
  organizationId: true,
  title: true,
  description: true,
  requiredSkills: true,
  preferredSkills: true,
  languages: true,
  locations: true,
  remoteAllowed: true,
  createdAt: true,
} satisfies Prisma.JobDescriptionSelect;

/** A job with all fields the ingestion and matching code needs. */
export type JobDetails = Prisma.JobDescriptionGetPayload<{ select: typeof jobSelect }>;

/**
 * Loads one job, but only if it belongs to the given organization.
 * Returning null for both "missing" and "someone else's" avoids leaking which ids exist.
 */
export async function findJobInOrganization(
  jobId: string,
  organizationId: string,
): Promise<JobDetails | null> {
  return prisma.jobDescription.findFirst({
    where: { id: jobId, organizationId },
    select: jobSelect,
  });
}

/** One row in the jobs list. */
export interface JobListItem {
  id: string;
  title: string;
  createdAt: Date;
  matchCount: number;
}

/**
 * Lists an organization's jobs with the number of completed matches, in ONE query
 * (a LEFT JOIN + GROUP BY instead of counting per job).
 */
export async function listJobsWithMatchCounts(organizationId: string): Promise<JobListItem[]> {
  return prisma.$queryRaw<JobListItem[]>`
    SELECT j."id", j."title", j."createdAt", COUNT(m."id")::int AS "matchCount"
    FROM job_descriptions j
    LEFT JOIN match_scores m ON m."jobId" = j."id" AND m."status" = 'completed'
    WHERE j."organizationId" = ${organizationId}::uuid
    GROUP BY j."id"
    ORDER BY j."createdAt" DESC
  `;
}
