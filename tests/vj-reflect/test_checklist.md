# VJ-Reflect Rubber Duck Test Checklist

## Pre-flight

- [ ] `synthetic_session.jsonl` is valid JSONL (38 lines, each parses)
- [ ] `pwsh` available (`C:\Program Files\PowerShell\7\pwsh.exe`)
- [ ] `claude` CLI available in PATH
- [ ] `vj-reflect` skill exists at `~/.claude/skills/vj-reflect/SKILL.md`
- [ ] No `VJ_REFLECTING` env var set before test

## Test Run

```powershell
cd C:\workspace\claude
pwsh -File tests/vj-reflect/run_test.ps1
```

## Automated Checks (run_test.ps1)

- [ ] **JSON parse**: `claude -p` output is valid JSON (no markdown fences, no trailing text)
- [ ] **quality_score type**: float between 0.0 and 1.0
- [ ] **quality_score range**: between 0.20 and 0.65 (low enough to catch seeded issues, not zero)
- [ ] **improvements count**: 1-3 entries
- [ ] **rules count**: 0-5 entries
- [ ] **Shell/OS detection**: at least 1 improvement or rule about OS/shell mismatch or post-compaction verification
- [ ] **Retry detection**: at least 1 improvement or rule about retry limits or search re-scoping
- [ ] **Token bloat detection**: at least 1 improvement or rule about token/context management
- [ ] **Generalization check**: rules contain NO specific file paths (like `src/config.py`)
- [ ] **Generalization check**: rules contain NO specific error messages
- [ ] **Domain tag check**: at least 1 rule uses `Context:` tag format

## Manual Verification

- [ ] **No hallucinations**: All reported issues correspond to seeded problems in the transcript
- [ ] **No missed major issues**: All 5 seeded categories detected (tool errors, retries, bloat, compaction, overengineering)
- [ ] **Rule quality**: Rules express reusable principles, not one-off observations
- [ ] **Improvement quality**: Improvements are actionable and specific to the patterns seen
- [ ] **Tone**: No security warnings triggered (none seeded)

## Edge Cases to Watch

- [ ] `claude -p` completes within 60 seconds (180s timeout in runner)
- [ ] Model doesn't hallucinate security issues from benign code
- [ ] Model doesn't penalize the task-completion success (test passed!)
- [ ] Post-compaction context loss IS detected as a pattern
- [ ] The Glob->Glob->Glob->Grep pivot is recognized as a retry/inefficiency pattern

## After Test

- [ ] `vj-lessons.jsonl` was NOT modified by this test (test uses direct `claude -p`, not the hook)
- [ ] If test created any temp files, clean them up
- [ ] Results logged to `tests/vj-reflect/last_test_result.json`

## Pass Threshold

**Minimum passing**: 10/11 automated checks pass. The only acceptable failure is a single `expected_detections` coverage gap.

**Full passing**: All automated checks + all manual verification items confirmed.
