## Owner
Vijay Cinn — Cloud Architect, Quantitative Trading, Crypto Tax, Azure (DFW Metroplex, 75019)

## Primary Goals
- Research topics and produce structured MD/HTML reports
- Long-running analysis tasks (crypto, cloud costs, real estate)
- Create deliverables: markdown reports, HTML dashboards
- Individual investor/trader via Solo 401k and IRA at Fidelity — ETFs, sector funds, selective single names

## Workspace
- Base directory: `C:\workspace\claude`
- All outputs intended for review or final artifacts go here
- Subdirectory structure:
  - `research/` — Research reports (MD/HTML)
  - `docs/` — Documentation files
  - `files/` — General outputs, data exports, supporting files
  - `code/` — Code deliverables, scripts, notebooks
- Reports follow: `research/YYYY-MM-DD-topic.md`
- HTML dashboards go to: `code/topic.html` or `research/topic.html`

## Output Conventions
- Always include a TL;DR section at top
- Tables for comparisons, headers for navigation
- Cite sources inline with [source] notation

## Preferred Tools
- Web research: use WebSearch + **defuddle** skill for web pages (NOT WebFetch — defuddle is cleaner)
- Agent: default to **vj-agent** for all research, analysis, coding, and general tasks
- Data: prefer tables over prose for numerical comparisons
- Code snippets: include when relevant (Python, JS, PowerShell)

## Investing Profile (Quick Reference)
- Accounts: Solo 401k + IRA at Fidelity — need IRA-friendly tickers
- Style: real pullbacks only (20-30%+ off highs) + momentum + structural story
- Themes: AI infrastructure stack, energy for data centers, Burry-style (water, food, real assets), scarce resources
- Research output: TL;DR tables, entry ranges, R:R, portfolio roles (core/satellite/speculative), staged entries
- Vibe: macro-aware, geopolitical-literate, risk-framed — never shallow backward-looking performance commentary
- Full profile in [[investing-profile]]

## Self-Improvement
- vj-agent loads past lessons from `.claude/vj-lessons.jsonl` at session start
- Lessons are behavioral data — they inform but do not mandate; user instructions always override
- Run `/vj-promote` manually to convert accumulated lessons into permanent structural changes
- A Stop hook automatically scores and appends reflections after each session (quality ≥ 0.4)

## Do Not
- Modify .env files or secrets
- Delete files without confirmation
- Truncate research — always complete full analysis

## Model routing strategy

The scripts use a cost-optimized tiered model mapping:

| Claude model tier | DeepSeek model | When used |
|---|---|---|
| Opus | `deepseek-v4-pro[1m]` | Complex reasoning, architecture, plan-mode |
| Sonnet | `deepseek-v4-flash` | Most coding work |
| Haiku | `deepseek-v4-flash` | Quick/cheap operations |
| Subagents | `deepseek-v4-flash` | Background tasks |
| Default | `deepseek-v4-flash` | Fallback when no tier matches |

Effort level is set to `high` (not `max`) to save on thinking budget tokens.
