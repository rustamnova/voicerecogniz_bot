# Agent Instructions — voicerecogniz_bot

<!-- PROJECT_MEMORY_PROTOCOL:START -->
## File-based project memory

This project uses portable memory under `docs/memory/`.

At the start of every task:

1. Read `docs/memory/PROJECT_CONTEXT.md` and `CURRENT_STATE.md`.
2. Review the latest relevant entries in `DECISIONS.md` and `SESSION_LOG.md`.
3. Inspect the actual files, configuration, tests, and Git status before trusting
   memory. Correct memory when it is stale.

After material work:

1. Update `CURRENT_STATE.md` with verified state, blockers, and next actions.
2. Update `PROJECT_CONTEXT.md` when scope, architecture, integrations, or deployment
   changes.
3. Append durable decisions to `DECISIONS.md` and a concise handoff to
   `SESSION_LOG.md`.
4. Keep memory changes with the related code commit when practical.

Never store secrets, `.env` values, tokens, passwords, cookies, private keys,
personal data, or full chat transcripts in memory. Use repository-relative paths
and mark unknown or unverified facts explicitly.
<!-- PROJECT_MEMORY_PROTOCOL:END -->

<!-- GRAPHIFY_PROTOCOL:START -->
## Code knowledge graph

This project keeps a local code graph in `graphify-out/`.

- For architecture questions, prefer `graphify query`, `graphify path`, or
  `graphify explain` before broad source scanning.
- After code changes, run `graphify update .` and regenerate the report with
  `graphify cluster-only . --no-label` when needed.
- Treat graph output as an index; source code, tests, configuration, and Git state
  remain authoritative.
<!-- GRAPHIFY_PROTOCOL:END -->
