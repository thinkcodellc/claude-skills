# Claude Skills — VJ-Agent Portable Configuration

Portable backup of Vijay's Claude Code customizations. Clone anywhere to replicate the full VJ-Agent environment — skills, agents, hooks, MCP servers, settings, and self-improvement pipeline.

## Complete Skill Catalog

### Custom Skills (included in this repo)

| Skill | Source | Trigger |
|---|---|---|
| `/vj-reflect` | This repo | Post-session reflection — scores transcript, extracts improvements + rules |
| `/vj-promote` | This repo | Manual: cluster recurring lessons → propose CLAUDE.md/vj-agent.md edits |
| `/defuddle` | This repo + binary | Extract clean markdown from web pages, YouTube, podcasts, PDFs, academic papers |

### Plugin Skills (install separately)

These come from the **`document-skills@anthropic-agent-skills`** plugin (source: [anthropics/skills](https://github.com/anthropics/skills)):

| Skill | What it does |
|---|---|
| `docx` | Create, read, edit Word documents (.docx) — reports, memos, letters, templates |
| `pptx` | Create, read, edit PowerPoint presentations (.pptx) — slide decks, pitch decks |
| `pdf` | Read, merge, split, watermark, OCR, fill forms in PDF files |
| `xlsx` | Create, read, edit spreadsheets (.xlsx, .csv, .tsv) — formulas, charts, data cleaning |
| `frontend-design` | Production-grade frontend interfaces — websites, dashboards, React components |
| `canvas-design` | Static visual art and design — posters, graphics, layouts (.png, .pdf) |
| `web-artifacts-builder` | Complex claude.ai HTML artifacts — React + Tailwind + shadcn/ui |
| `webapp-testing` | Test local web apps with Playwright — screenshots, debugging, browser logs |
| `algorithmic-art` | Generative art with p5.js — flow fields, particle systems, seeded randomness |
| `brand-guidelines` | Apply Anthropic brand colors and typography to artifacts |
| `theme-factory` | Style artifacts with 10 pre-set themes or generate custom themes |
| `slack-gif-creator` | Animated GIFs optimized for Slack |
| `claude-api` | Build/debug/optimize Anthropic SDK apps — caching, tool use, model migration |
| `mcp-builder` | Create MCP servers — Python (FastMCP) or Node/TypeScript (MCP SDK) |
| `skill-creator` | Create, modify, benchmark, and optimize skills |
| `internal-comms` | Internal communications — status reports, FAQs, incident reports, newsletters |
| `doc-coauthoring` | Structured co-authoring workflow for docs, proposals, technical specs |

### Plugin Install Command

```bash
claude plugin install document-skills@anthropic-agent-skills
```

## MCP Servers

Two MCP servers are configured in `settings.json`:

| Server | Endpoint | Purpose |
|---|---|---|
| **ms-learn** | `https://learn.microsoft.com/api/mcp` (HTTP) | Microsoft/Azure docs: search, code samples, full page fetch |
| **github** | `https://api.githubcopilot.com/mcp` (HTTP) | GitHub: repos, PRs, issues, commits, code search, Copilot review |

### MCP Setup

```bash
# GitHub MCP (requires GitHub Copilot access)
claude mcp add github https://api.githubcopilot.com/mcp

# Microsoft Learn
claude mcp add ms-learn https://learn.microsoft.com/api/mcp
```

**Note**: GitHub MCP uses Copilot's API endpoint (not a personal access token). If you don't have Copilot, use the standard `github` MCP server with a PAT instead.

## Quick Install

```powershell
git clone https://github.com/thinkcodellc/claude-skills.git
cd claude-skills
pwsh -File install.ps1
```

### Full Bootstrap (new PC)

```powershell
# 1. Clone this repo
git clone https://github.com/thinkcodellc/claude-skills.git
cd claude-skills

# 2. Install custom skills, agents, hooks, settings
pwsh -File install.ps1

# 3. Install document skills plugin
claude plugin install document-skills@anthropic-agent-skills

# 4. Connect MCP servers
claude mcp add github https://api.githubcopilot.com/mcp
claude mcp add ms-learn https://learn.microsoft.com/api/mcp

# 5. Create lessons file
New-Item -Path ".claude\vj-lessons.jsonl" -ItemType File

# 6. Verify self-improvement pipeline
pwsh -File tests/vj-reflect/run_test.ps1

# 7. Restart Claude Code
```

### What install.ps1 does

1. Copies `skills/*` → `~/.claude/skills/` (vj-reflect, vj-promote, defuddle)
2. Copies `agents/*` → `~/.claude/agents/` (vj-agent.md)
3. Copies `hooks/*` → `~/.claude/hooks/` (stop-vj-reflect.ps1)
4. Merges `settings/settings.json` → `~/.claude/settings.json` (backs up existing)
5. Copies `claude-md/CLAUDE.md` → workspace root (warns if exists)
6. Copies `tests/` → workspace `tests/`

### Manual steps after install

- **defuddle binary**: Install the Defuddle CLI — this repo includes the `SKILL.md` but not the Python script (`defuddle.py`) or compiled binary. See [defuddle docs](https://github.com/anthropics/skills/tree/main/skills/defuddle).
- **settings.json**: Review paths, model preferences, and adjust for the target machine. The Stop hook path is hardcoded to `C:\Users\vijay\.claude\hooks\stop-vj-reflect.ps1` — update if your username differs.
- **GitHub auth**: Run `gh auth login` if using GitHub MCP features that need authentication.

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

## Source Repositories

| Component | Source |
|---|---|
| vj-reflect, vj-promote, vj-agent, stop-vj-reflect.ps1 | This repo — built from scratch |
| defuddle (SKILL.md) | [anthropics/skills](https://github.com/anthropics/skills) |
| document-skills (docx, pptx, pdf, xlsx, …) | [anthropics/skills](https://github.com/anthropics/skills) |
| settings.json structure | Claude Code default + custom hooks/permissions |
| ms-learn MCP | [Microsoft Learn MCP](https://learn.microsoft.com/api/mcp) |
| github MCP | [GitHub Copilot MCP](https://api.githubcopilot.com/mcp) |
| agent-tuning inspiration | [adam-s/agent-tuning](https://github.com/adam-s/agent-tuning) |
| recursive-improve inspiration | [kayba-ai/recursive-improve](https://github.com/kayba-ai/recursive-improve) |

## Test the Pipeline

```powershell
cd C:\workspace\claude
pwsh -File tests/vj-reflect/run_test.ps1 -Verbose
```

## File Map

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
