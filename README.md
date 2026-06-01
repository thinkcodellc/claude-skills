# Claude Skills — VJ-Agent Portable Configuration

Portable backup of Vijay's Claude Code customizations. Clone anywhere to replicate the full VJ-Agent environment with self-improvement pipeline.

## What's Inside

| Directory | Contents | Purpose |
|---|---|---|
| `skills/` | vj-reflect, vj-promote, defuddle | Custom skills for reflection, promotion, web content extraction |
| `agents/` | vj-agent.md | VJ-Agent persona: research analyst, cloud architect, crypto/quant domain expert |
| `hooks/` | stop-vj-reflect.ps1 | Stop hook script — post-session transcript analysis via claude -p |
| `settings/` | settings.json, project-settings.json | Global and project-level Claude Code configuration |
| `tests/` | vj-reflect test suite | Rubber duck test: synthetic transcript, automated validator, checklist |
| `claude-md/` | CLAUDE.md | Project conventions, model routing, self-improvement rules |
| `memory/` | README.md | Memory file structure documentation |

## Self-Improvement Pipeline

```
SESSION ENDS → Stop hook fires
  → stop-vj-reflect.ps1 reads transcript
  → claude -p scores session (quality_score, improvements, rules)
  → Appends to .claude/vj-lessons.jsonl (if score ≥ 0.4)

NEXT SESSION → vj-agent loads last 10 lessons
  → Applies relevant rules (user instructions always override)

ACCUMULATE → User runs /vj-promote
  → Clusters recurring rules (≥3 occurrences)
  → Proposes structural edits to CLAUDE.md or agent definition
  → User approves → applied
```

Design principles: **data before code** (lessons are JSONL, not live edits), **one control point** (Stop hook only), **human gate on structural changes** (/vj-promote is manual).

## Quick Install

```powershell
git clone https://github.com/thinkcodellc/claude-skills.git
cd claude-skills
pwsh -File install.ps1
```

### What install.ps1 does

1. Copies `skills/*` → `~/.claude/skills/`
2. Copies `agents/*` → `~/.claude/agents/`
3. Copies `hooks/*` → `~/.claude/hooks/`
4. Merges `settings/settings.json` → `~/.claude/settings.json` (backs up existing, shows diff)
5. Copies `claude-md/CLAUDE.md` → workspace root (with warning if exists)
6. Copies `tests/` → workspace `tests/`

### Manual steps after install

- **defuddle**: Install the Defuddle CLI binary and `defuddle.py` separately
- **settings.json**: Review the merged settings — adjust paths, API keys, model preferences for the target machine
- **CLAUDE.md**: If you already have a CLAUDE.md, manually merge the Self-Improvement section
- **Lessons file**: Create `.claude/vj-lessons.jsonl` (empty) in your workspace

## Test the Pipeline

```powershell
cd C:\workspace\claude
pwsh -File tests/vj-reflect/run_test.ps1 -Verbose
```

Should pass 14+/16 automated checks on the synthetic transcript.

## File Map (source → repo)

| Original Location | Repo Path |
|---|---|
| `~/.claude/skills/vj-reflect/SKILL.md` | `skills/vj-reflect/SKILL.md` |
| `~/.claude/skills/vj-promote/SKILL.md` | `skills/vj-promote/SKILL.md` |
| `~/.claude/skills/defuddle/SKILL.md` | `skills/defuddle/SKILL.md` |
| `~/.claude/agents/vj-agent.md` | `agents/vj-agent.md` |
| `~/.claude/hooks/stop-vj-reflect.ps1` | `hooks/stop-vj-reflect.ps1` |
| `~/.claude/settings.json` | `settings/settings.json` |
| `{workspace}/.claude/settings.local.json` | `settings/project-settings.json` |
| `{workspace}/CLAUDE.md` | `claude-md/CLAUDE.md` |
| `{workspace}/tests/vj-reflect/*` | `tests/vj-reflect/*` |

## Version

Created 2026-05-31. Self-improvement pipeline v1 — manual reflection with /vj-promote gate.

🤖 Built with [Claude Code](https://claude.com/claude-code)
