-- TalentGraph baseline migration.
-- Sections 1-3 mirror prisma/schema.prisma (what `prisma migrate dev --create-only` produces).
-- Section 4 is hand-written: things Prisma cannot express (CHECK constraints, HNSW vector indexes).

-- ============================================================
-- 1. Extension and enums
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "vector";

CREATE TYPE "BatchStatus" AS ENUM ('queued', 'running', 'completed', 'failed');
CREATE TYPE "MatchStatus" AS ENUM ('pending', 'completed', 'failed');

-- ============================================================
-- 2. Tables
-- ============================================================
CREATE TABLE "organizations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "organizations_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "recruiters" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organizationId" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recruiters_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "oauth_tokens" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recruiterId" UUID NOT NULL,
    "provider" TEXT NOT NULL,
    "encryptedToken" TEXT NOT NULL,
    "scopes" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "expiresAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "oauth_tokens_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "job_descriptions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organizationId" UUID NOT NULL,
    "createdById" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "requiredSkills" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "preferredSkills" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "languages" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "locations" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "remoteAllowed" BOOLEAN NOT NULL DEFAULT false,
    "embedding" vector(1536),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "job_descriptions_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "candidates" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "githubId" BIGINT NOT NULL,
    "login" TEXT NOT NULL,
    "name" TEXT,
    "avatarUrl" TEXT,
    "profileUrl" TEXT NOT NULL,
    "bio" TEXT,
    "location" TEXT,
    "githubCreatedAt" TIMESTAMPTZ(3),
    "yearsActive" DOUBLE PRECISION,
    "topLanguages" JSONB NOT NULL DEFAULT '{}',
    "topics" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "publicEmail" TEXT,
    "profileText" TEXT,
    "embedding" vector(1536),
    "lastIngestedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "candidates_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ingestion_batches" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "jobId" UUID NOT NULL,
    "requestedById" UUID NOT NULL,
    "status" "BatchStatus" NOT NULL DEFAULT 'queued',
    "maxProfiles" INTEGER NOT NULL DEFAULT 100,
    "profilesFound" INTEGER NOT NULL DEFAULT 0,
    "candidatesUpserted" INTEGER NOT NULL DEFAULT 0,
    "embeddedCount" INTEGER NOT NULL DEFAULT 0,
    "evaluatedCount" INTEGER NOT NULL DEFAULT 0,
    "failedCount" INTEGER NOT NULL DEFAULT 0,
    "error" TEXT,
    "startedAt" TIMESTAMPTZ(3),
    "finishedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ingestion_batches_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "match_scores" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "jobId" UUID NOT NULL,
    "candidateId" UUID NOT NULL,
    "batchId" UUID,
    "score" INTEGER,
    "matchedSkills" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "missingSkills" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "MatchStatus" NOT NULL DEFAULT 'pending',
    "model" TEXT,
    "error" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "match_scores_pkey" PRIMARY KEY ("id")
);

-- ============================================================
-- 3. Indexes and foreign keys
-- ============================================================
CREATE INDEX "organizations_createdAt_idx" ON "organizations"("createdAt");
CREATE INDEX "organizations_updatedAt_idx" ON "organizations"("updatedAt");

CREATE UNIQUE INDEX "recruiters_email_key" ON "recruiters"("email");
CREATE INDEX "recruiters_organizationId_idx" ON "recruiters"("organizationId");
CREATE INDEX "recruiters_createdAt_idx" ON "recruiters"("createdAt");
CREATE INDEX "recruiters_updatedAt_idx" ON "recruiters"("updatedAt");

CREATE UNIQUE INDEX "oauth_tokens_recruiterId_provider_key" ON "oauth_tokens"("recruiterId", "provider");
CREATE INDEX "oauth_tokens_createdAt_idx" ON "oauth_tokens"("createdAt");
CREATE INDEX "oauth_tokens_updatedAt_idx" ON "oauth_tokens"("updatedAt");

CREATE INDEX "job_descriptions_organizationId_createdAt_idx" ON "job_descriptions"("organizationId", "createdAt");
CREATE INDEX "job_descriptions_createdById_idx" ON "job_descriptions"("createdById");
CREATE INDEX "job_descriptions_updatedAt_idx" ON "job_descriptions"("updatedAt");

CREATE UNIQUE INDEX "candidates_githubId_key" ON "candidates"("githubId");
CREATE INDEX "candidates_login_idx" ON "candidates"("login");
CREATE INDEX "candidates_createdAt_idx" ON "candidates"("createdAt");
CREATE INDEX "candidates_updatedAt_idx" ON "candidates"("updatedAt");

CREATE INDEX "ingestion_batches_status_createdAt_idx" ON "ingestion_batches"("status", "createdAt");
CREATE INDEX "ingestion_batches_jobId_createdAt_idx" ON "ingestion_batches"("jobId", "createdAt");
CREATE INDEX "ingestion_batches_requestedById_idx" ON "ingestion_batches"("requestedById");
CREATE INDEX "ingestion_batches_updatedAt_idx" ON "ingestion_batches"("updatedAt");

CREATE UNIQUE INDEX "match_scores_jobId_candidateId_key" ON "match_scores"("jobId", "candidateId");
CREATE INDEX "match_scores_jobId_score_idx" ON "match_scores"("jobId", "score" DESC);
CREATE INDEX "match_scores_candidateId_idx" ON "match_scores"("candidateId");
CREATE INDEX "match_scores_batchId_idx" ON "match_scores"("batchId");
CREATE INDEX "match_scores_createdAt_idx" ON "match_scores"("createdAt");
CREATE INDEX "match_scores_updatedAt_idx" ON "match_scores"("updatedAt");

ALTER TABLE "recruiters" ADD CONSTRAINT "recruiters_organizationId_fkey"
    FOREIGN KEY ("organizationId") REFERENCES "organizations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "oauth_tokens" ADD CONSTRAINT "oauth_tokens_recruiterId_fkey"
    FOREIGN KEY ("recruiterId") REFERENCES "recruiters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "job_descriptions" ADD CONSTRAINT "job_descriptions_organizationId_fkey"
    FOREIGN KEY ("organizationId") REFERENCES "organizations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "job_descriptions" ADD CONSTRAINT "job_descriptions_createdById_fkey"
    FOREIGN KEY ("createdById") REFERENCES "recruiters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "ingestion_batches" ADD CONSTRAINT "ingestion_batches_jobId_fkey"
    FOREIGN KEY ("jobId") REFERENCES "job_descriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ingestion_batches" ADD CONSTRAINT "ingestion_batches_requestedById_fkey"
    FOREIGN KEY ("requestedById") REFERENCES "recruiters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "match_scores" ADD CONSTRAINT "match_scores_jobId_fkey"
    FOREIGN KEY ("jobId") REFERENCES "job_descriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "match_scores" ADD CONSTRAINT "match_scores_candidateId_fkey"
    FOREIGN KEY ("candidateId") REFERENCES "candidates"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "match_scores" ADD CONSTRAINT "match_scores_batchId_fkey"
    FOREIGN KEY ("batchId") REFERENCES "ingestion_batches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================================
-- 4. HAND-EDITED: things Prisma cannot express
-- ============================================================

-- Score must be 0-100 (NULL is allowed while a match is pending or failed).
ALTER TABLE "match_scores"
    ADD CONSTRAINT "match_scores_score_range_chk"
    CHECK ("score" IS NULL OR ("score" >= 0 AND "score" <= 100));

-- A completed match must always carry a score.
ALTER TABLE "match_scores"
    ADD CONSTRAINT "match_scores_completed_has_score_chk"
    CHECK ("status" <> 'completed' OR "score" IS NOT NULL);

-- HNSW cosine indexes for nearest-neighbour search on embeddings.
-- (Queries must use the <=> cosine distance operator to benefit from them.)
CREATE INDEX "candidates_embedding_hnsw_idx"
    ON "candidates" USING hnsw ("embedding" vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

CREATE INDEX "job_descriptions_embedding_hnsw_idx"
    ON "job_descriptions" USING hnsw ("embedding" vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
