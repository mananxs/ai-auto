import { prisma } from "@/server/db";

/** The small recruiter shape the API needs for authorization checks. */
export interface RecruiterContext {
  id: string;
  email: string;
  name: string;
  organizationId: string;
}

/**
 * Finds a recruiter by email (one query).
 * Used by DEV_AUTH to load the seeded recruiter.
 */
export async function findRecruiterByEmail(email: string): Promise<RecruiterContext | null> {
  return prisma.recruiter.findUnique({
    where: { email },
    select: { id: true, email: true, name: true, organizationId: true },
  });
}
