# Memory File Structure

This directory mirrors what lives at `.claude/memory/` in the workspace. These files track the self-improvement cycle.

## Files

| File | Purpose |
|---|---|
| `MEMORY.md` | Auto-generated index of all memory files |
| `cycle_history.md` | Log of all /vj-promote structural edits and self-improvement cycles |
| `auto_rules.md` | Rules extracted from user corrections (>3 occurrences of same correction) |

## External (not in repo)

These live in the workspace `.claude/` directory and are NOT source-controlled:

| File | Purpose |
|---|---|
| `vj-lessons.jsonl` | Append-only reflection output from Stop hook (one JSON object per line) |
| `improvement_scratchpad.md` | Per-session reflection scratchpad (overwritten each cycle) |
| `ideas_log.md` | Parked observations that were suppressed by anti-spam rules |

## Lessons JSONL Format

Each line in `vj-lessons.jsonl`:

```json
{
  "timestamp": "2026-06-01T14:30:00+05:30",
  "session_id": "9ff9b618-16a9-4bbf-9431-aa012b4357bf",
  "quality_score": 0.7,
  "improvements": ["After context compaction, verify working directory and OS before shell commands."],
  "rules": ["Bash: On Windows, use PowerShell syntax and pwsh; never assume bash availability after compaction."],
  "model": "deepseek-v4-flash",
  "error_count": 3,
  "input_tokens": 45000,
  "output_tokens": 3200
}
```
