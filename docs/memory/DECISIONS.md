# Decisions

Record only durable decisions that affect future work. Append new entries; do not
rewrite history silently.

## 2026-08-09 — Adopt file-based project memory

- Status: Accepted
- Decision: Keep durable Codex instructions in `AGENTS.md` and portable project
  context in `docs/memory/`.
- Rationale: The project must remain understandable when opened from another device
  without depending on a previous chat thread.
- Consequences: Material work should update current state and session handoff files;
  secrets and full transcripts must remain outside project memory.
