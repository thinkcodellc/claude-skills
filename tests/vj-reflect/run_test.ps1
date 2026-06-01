# run_test.ps1 — Rubber Duck Test for vj-reflect skill
# Feeds a synthetic session transcript to claude -p, validates reflection output.
#
# Usage: pwsh -File tests/vj-reflect/run_test.ps1
#        pwsh -File tests/vj-reflect/run_test.ps1 -Verbose  (show claude response)

param([switch]$Verbose)

$ErrorActionPreference = "Stop"
$TEST_DIR = Split-Path $PSCommandPath -Parent
$TRANSCRIPT = Join-Path $TEST_DIR "synthetic_session.jsonl"
$EXPECTED = Join-Path $TEST_DIR "expected_output.json"
$RESULT_FILE = Join-Path $TEST_DIR "last_test_result.json"

Write-Host "`n═══ VJ-Reflect Rubber Duck Test ═══`n" -ForegroundColor Cyan

# ── Pre-flight ───────────────────────────────────────────────────
if (-not (Test-Path $TRANSCRIPT)) {
    Write-Host "❌ Transcript not found: $TRANSCRIPT" -ForegroundColor Red
    exit 1
}
$transcriptLines = Get-Content $TRANSCRIPT
Write-Host "📄 Transcript: $($transcriptLines.Count) lines"

$claudePath = (Get-Command "claude" -ErrorAction SilentlyContinue).Source
if (-not $claudePath) {
    Write-Host "❌ claude CLI not found in PATH" -ForegroundColor Red
    exit 1
}
Write-Host "🔧 Claude CLI: $claudePath"

$spec = Get-Content $EXPECTED -Raw | ConvertFrom-Json

# ── Build reflection prompt ──────────────────────────────────────
$maxLines = 200
$tail = if ($transcriptLines.Count -gt $maxLines) {
    $transcriptLines[-$maxLines..-1]
} else {
    $transcriptLines
}

# Extract quick stats for the prompt header
$errorCount = 0
$tokenPeak = 0
$compactionCount = 0
foreach ($line in $tail) {
    try {
        $entry = $line | ConvertFrom-Json
        if ($entry.type -eq "user" -and $entry.message.content) {
            foreach ($block in $entry.message.content) {
                if ($block.is_error) { $errorCount++ }
            }
        }
        if ($entry.type -eq "assistant" -and $entry.message.usage) {
            $t = [int]($entry.message.usage.input_tokens -as [int])
            if ($t -gt $tokenPeak) { $tokenPeak = $t }
        }
        if ($entry.type -eq "system" -and $entry.message.content) {
            foreach ($block in $entry.message.content) {
                if ($block.text -match "ompact") { $compactionCount++ }
            }
        }
    } catch {}
}

# Inline the vj-reflect skill prompt (matches SKILL.md)
$reflectionPrompt = @"
You are a post-session reflection agent. Analyze this Claude Code session transcript and output ONLY valid JSON (no markdown code fences, no backticks, no commentary, no trailing text).

OUTPUT SCHEMA:
{
  "quality_score": 0.0,
  "improvements": [],
  "rules": []
}

quality_score (0.0-1.0):
- 0.0-0.3: Multiple critical failures, wasted substantial tokens, ignored user instructions
- 0.4-0.6: Completed task but with notable inefficiencies or minor errors
- 0.7-0.8: Solid execution, minor improvements possible
- 0.9-1.0: Exceptional — efficient, error-free, proactively surfaced value

improvements[]: 1-3 concrete, imperative suggestions. Generalize — no specific filenames, URLs, or error messages.

rules[]: 0-5 reusable behavioral rules. Format as "Context: Rule". Examples:
- "Bash: Verify the OS and shell type after any context compaction before issuing commands."
- "Error-handling: When a tool returns 'permission denied', check the allowlist before retrying."
- "Research: After 3 tool calls without clear progress, pause and summarize findings before continuing."

ANALYSIS PRIORITIES (in order):
1. Tool errors & retries: What failed? Why? Same tool called repeatedly on same target?
2. Token bloat signs: Any turns >50K input tokens? Did compaction happen? Behavior change after compaction?
3. Workflow anti-patterns: Implementing before checking? Building without testing? Overengineering?
4. Missed opportunities: Were user preferences ignored? Was a faster path available?

SAFETY GUARD: Never propose changes that place trades, modify private keys, bypass safety rules, or expose credentials.

SESSION STATS:
- Error count: $errorCount
- Peak input tokens: $tokenPeak
- Compaction events: $compactionCount
- Total lines in transcript: $($transcriptLines.Count)

TRANSCRIPT:
$($tail -join "`n")
"@

Write-Host "📝 Reflection prompt: $($reflectionPrompt.Length) chars"

# ── Run reflection ───────────────────────────────────────────────
Write-Host "🤖 Running claude -p (timeout: 180s)...`n" -ForegroundColor Yellow

$env:VJ_REFLECTING = "1"  # Recursion guard
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $rawOutput = & $claudePath -p $reflectionPrompt 2>&1
    $stopwatch.Stop()
    Write-Host "⏱️  Completed in $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s"
} catch {
    $stopwatch.Stop()
    Write-Host "❌ claude -p failed after $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s: $_" -ForegroundColor Red
    $env:VJ_REFLECTING = ""
    exit 1
}
$env:VJ_REFLECTING = ""

if ($Verbose) {
    Write-Host "`n── RAW OUTPUT ──`n$rawOutput`n── END OUTPUT ──`n" -ForegroundColor DarkGray
}

# ── Parse reflection JSON ────────────────────────────────────────
$jsonText = $rawOutput -join "`n"
# Strip markdown code fences
$jsonText = $jsonText -replace '```json\s*', '' -replace '```\s*$', '' -replace '^```\s*', ''
$jsonText = $jsonText.Trim()

# Try to extract just the JSON object
if ($jsonText -match '(\{[\s\S]*"quality_score"[\s\S]*\})') {
    $jsonText = $matches[1]
}

$reflection = $null
try {
    $reflection = $jsonText | ConvertFrom-Json
} catch {
    Write-Host "❌ Failed to parse reflection JSON: $_" -ForegroundColor Red
    Write-Host "   First 500 chars of output: $($jsonText.Substring(0, [Math]::Min(500, $jsonText.Length)))"
    exit 1
}

Write-Host "✅ JSON parsed successfully" -ForegroundColor Green

# ── Run validation checks ────────────────────────────────────────
$checks = @()
$passes = 0
$failures = 0

function Check($name, $condition, $detail) {
    $script:checks += @{ name = $name; pass = $condition; detail = $detail }
    if ($condition) {
        $script:passes++
        Write-Host "   ✅ $name" -ForegroundColor Green
    } else {
        $script:failures++
        Write-Host "   ❌ $name — $detail" -ForegroundColor Red
    }
}

Write-Host "`n── Validation Checks ──`n"

# Schema checks
$qs = $reflection.quality_score
$improvements = @($reflection.improvements)
$rules = @($reflection.rules)

Check "quality_score is a number" ($qs -is [double] -or $qs -is [int]) "Got: $qs"
Check "quality_score in range [0.0, 1.0]" ($qs -ge 0.0 -and $qs -le 1.0) "Got: $qs"
Check "quality_score <= 0.65 (catches seeded issues)" ($qs -le 0.65) "Got: $qs — if >0.65, model missed errors"
Check "quality_score >= 0.15 (not catastrophic)" ($qs -ge 0.15) "Got: $qs — if <0.15, model may be over-penalizing"
Check "improvements has 1-3 entries" ($improvements.Count -ge 1 -and $improvements.Count -le 5) "Got: $($improvements.Count)"
Check "rules has 0-8 entries" ($rules.Count -le 8) "Got: $($rules.Count)"

# Merge all text for semantic checks
$allImprovements = ($improvements -join " ")
$allRules = ($rules -join " ")
$allText = "$allImprovements $allRules"

# Seeded issue detection
Check "Detects OS/shell mismatch" (
    $allText -match "(?i)(shell|OS|operating system|bash|powershell|pwsh|verify.*environment|after.*compact)"
) "Check for shell/OS awareness in improvements or rules"

Check "Detects retry/re-scoping pattern" (
    $allText -match "(?i)(retry|re-scop|repeated|same.*tool|limit.*attempt|switch.*tool|after.*fail)"
) "Check for retry pattern detection"

Check "Detects token/context bloat" (
    $allText -match "(?i)(token|context|compact|budget|bloat|input.*size|context.*management)"
) "Check for token/context management awareness"

Check "Detects post-compaction behavior change" (
    $allText -match "(?i)(after.*compact|post.*compact|compact.*after|context.*loss|recheck|verify.*after)"
) "Check for post-compaction recheck awareness"

# Generalization checks
$specificFiles = $rules | Where-Object { $_ -match "src/config\.py|tests/test_config\.py|app\.json" }
Check "Rules are generalized (no specific file paths)" (
    $specificFiles.Count -eq 0
) "Found specific paths in: $($specificFiles -join '; ')"

$specificErrors = $rules | Where-Object { $_ -match "No such file|file or directory not found" }
Check "Rules are generalized (no specific error messages)" (
    $specificErrors.Count -eq 0
) "Found specific error fragments in: $($specificErrors -join '; ')"

# Rule format check
$taggedRules = $rules | Where-Object { $_ -match "^\w[\w-]*:" }
Check "At least 1 rule uses Context: tag format" (
    ($taggedRules.Count -gt 0) -or ($rules.Count -eq 0)
) "Got $($taggedRules.Count) tagged rules out of $($rules.Count)"

# Coverage check
$detectedCategories = 0
if ($allText -match "(?i)(shell|OS|bash|powershell|environment)") { $detectedCategories++ }
if ($allText -match "(?i)(retry|re-scop|repeated|same.*tool|limit)") { $detectedCategories++ }
if ($allText -match "(?i)(token|context|compact|budget|bloat)") { $detectedCategories++ }
if ($allText -match "(?i)(single.*edit|batch.*change|combine|overengin|minimal.*change)") { $detectedCategories++ }

Check "Detects at least 3 of 5 seeded issue categories" ($detectedCategories -ge 3) "Detected: $detectedCategories/5"

# Security: no false positives
$falseSecurity = $improvements + $rules | Where-Object { $_ -match "(?i)(security|credential|private.*key|secret|dangerous)" }
Check "No false security positives" ($falseSecurity.Count -eq 0) "Got: $($falseSecurity -join '; ')"

# ── Report ───────────────────────────────────────────────────────
$total = $checks.Count
Write-Host "`n═══ Results ═══" -ForegroundColor Cyan
Write-Host "   Passed: $passes/$total" -ForegroundColor $(if ($passes -eq $total) { "Green" } elseif ($passes -ge $total - 2) { "Yellow" } else { "Red" })
Write-Host "   Failed: $failures/$total" -ForegroundColor $(if ($failures -eq 0) { "Green" } else { "Red" })
Write-Host "   quality_score: $qs"
Write-Host "   improvements: $($improvements.Count)"
Write-Host "   rules: $($rules.Count)"

# ── Save results ─────────────────────────────────────────────────
$result = @{
    timestamp     = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
    passed        = $passes
    total         = $total
    quality_score = $qs
    improvements  = @($improvements)
    rules         = @($rules)
    checks        = $checks
    duration_sec  = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
} | ConvertTo-Json -Depth 3

$result | Out-File -FilePath $RESULT_FILE -Encoding UTF8
Write-Host "`n📁 Results saved: $RESULT_FILE"

if ($failures -eq 0) {
    Write-Host "`n🟢 ALL CHECKS PASSED — Reflection skill is working correctly.`n" -ForegroundColor Green
    exit 0
} elseif ($failures -le 2) {
    Write-Host "`n🟡 MOSTLY PASSED ($failures failures) — Minor prompt tuning may help.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n🔴 SIGNIFICANT FAILURES ($failures/$total) — Review raw output and adjust vj-reflect skill.`n" -ForegroundColor Red
    exit 1
}
