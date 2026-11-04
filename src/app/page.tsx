/** Temporary landing page. The real dashboard arrives in Phase 5. */
export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-xl flex-col justify-center gap-3 px-6">
      <h1 className="text-2xl font-semibold">TalentGraph</h1>
      <p className="text-slate-400">Phase 1 is running. The dashboard comes in Phase 5.</p>
      <a className="text-[#8b9cff] underline" href="/api/health">
        Check database health
      </a>
    </main>
  );
}
