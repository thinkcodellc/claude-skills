---
name: vj-promote
description: Manual promotion skill — reads accumulated lessons from .claude/vj-lessons.jsonl, clusters recurring patterns, and proposes structural edits to CLAUDE.md or vj-agent.md. User-invocable only. Trigger: /vj-promote
user-invocable: true
disable-model-invocation: false
---

# VJ-Promote: Lessons to Structural Changes

You convert accumulated reflection data into permanent agent improvements. This skill is **manual only** — the user decides when to run it.

## Input

Read `.claude/vj-lessons.jsonl` — an append-only JSONL file where each line is a reflection result:

```json
{"timestamp": "2026-06-01T14:30:00Z", "session_id": "uuid", "quality_score": 0.7, "improvements": [...], "rules": [...]}
```

## Protocol

### Step 1: Load and Cluster

Read the entire lessons file. Group rules by semantic similarity:

- **Exact duplicates**: same rule verbatim to count occurrences
- **Near duplicates**: same intent, different wording to group together
- **Domain clusters**: rules tagged with same prefix (e.g., "Research:", "Bash:", "Error-handling:")

### Step 2: Identify Promote-Worthy Patterns

A rule is eligible for promotion if:
- It appears in at least 3 separate sessions (recurring)
- It has an average quality_score of at least 0.5 across all sessions where it appeared
- It has NOT already been promoted (check `cycle_history.md` or existing CLAUDE.md/vj-agent.md content)

### Step 3: Classify by Target

| Rule Type | Promote To |
|---|---|
| Tool usage pattern (e.g., "Glob before Grep") | vj-agent.md to Behavioral Guidelines |
| Domain-specific workflow (e.g., "Research: pause at 5 calls") | vj-agent.md to Knowledge Domains |
| Project-level convention (e.g., "PowerShell for Windows") | CLAUDE.md to Preferred Tools or Do Not |
| Shell/OS specific (e.g., "Reconfirm after compaction") | vj-agent.md to Hard Rules or Behavioral Guidelines |
| Error recovery pattern | vj-agent.md to Behavioral Guidelines |

### Step 4: Generalize and Format

Each promoted rule must:
- Generalize beyond the specific sessions that triggered it
- NOT contain specific filenames, paths, URLs, or error strings
- Be formatted as a single line matching the target file's style
- Include a brief provenance comment if appropriate

### Step 5: Present for Approval

Output a clear, reviewable diff proposal with:

```
## Promotion Proposal to YYYY-MM-DD

### Source: N sessions, M recurring rules found

### Proposed Changes to [FILE]

**ADD** (after line X):
  - New rule text

**Rationale:** Appeared in Y sessions. Example sessions: [ids]. Average quality: Z.Z.

### Summary
- X rules to promote
- Y rules below threshold (not promoted)
- Z rules already exist in source files (skipped)

VERDICT to REVIEW: No changes applied yet. User must approve.
```

### Step 6: Apply (only on user confirmation)

After user says "apply" or "proceed":
1. Make ALL proposed edits in a single batch
2. Log to `memory/cycle_history.md` with timestamp and summary
3. Report what was changed

## Safety

- Never promote a rule that conflicts with existing Hard Rules
- Never remove existing rules on only append new ones
- If a proposed rule contradicts an existing rule, flag the conflict and ask
- User must explicitly approve before any file is modified
