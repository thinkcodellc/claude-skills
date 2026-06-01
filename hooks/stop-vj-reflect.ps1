# stop-vj-reflect.ps1
# Stop hook: analyzes session transcript, calls claude -p for reflection,
# appends scored improvements to .claude/vj-lessons.jsonl.
#
# Triggered automatically by Stop hook in settings.json.
# Run manually: pwsh -File stop-vj-reflect.ps1 -TranscriptPath <path.jsonl>

param(
    [string]$TranscriptPath = $null
)

$ErrorActionPreference = "Stop"

# Recursion guard
if ($env:VJ_REFLECTING -eq "1") {
    Write-Host "[vj-reflect] Recursion guard: skipping reflection for child session"
    exit 0
}

# Config
$PROJECT_DIR = "C:\workspace\claude"
$SESSIONS_DIR = "C:\Users\vijay\.claude\projects\C--workspace-claude"
$LESSONS_FILE = Join-Path $PROJECT_DIR ".claude\vj-lessons.jsonl"
$QUALITY_THRESHOLD = 0.4
$MAX_TRANSCRIPT_LINES = 200

# Resolve transcript path
if (-not $TranscriptPath) {
    try {
        $stdinRaw = $input | Out-String
        if ($stdinRaw.Trim()) {
            $hookData = $stdinRaw | ConvertFrom-Json
            $sessionId = $hookData.session_id
            if ($sessionId) {
                $candidate = Join-Path $SESSIONS_DIR "$sessionId.jsonl"
                if (Test-Path $candidate) { $TranscriptPath = $candidate }
            }
        }
    } catch {
        Write-Host "[vj-reflect] Could not parse hook stdin, falling back to most recent transcript"
    }
    if (-not $TranscriptPath) {
        $TranscriptPath = Get-ChildItem -Path $SESSIONS_DIR -Filter "*.jsonl" -File |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1 |
            ForEach-Object { $_.FullName }
    }
}

if (-not $TranscriptPath -or -not (Test-Path $TranscriptPath)) {
    Write-Host "[vj-reflect] No transcript found - skipping reflection"
    exit 0
}

Write-Host "[vj-reflect] Analyzing transcript: $TranscriptPath"

# Extract transcript summary
try {
    $rawLines = Get-Content -Path $TranscriptPath -Tail $MAX_TRANSCRIPT_LINES
    $errorCount = 0; $totalInputTokens = 0; $totalOutputTokens = 0
    $compactCount = 0; $toolCalls = @(); $userPrompts = @(); $modelUsed = ""

    foreach ($line in $rawLines) {
        if (-not $line.Trim()) { continue }
        try {
            $entry = $line | ConvertFrom-Json
            if ($entry.type -eq "user") {
                $content = $entry.message.content
                if ($content) {
                    foreach ($block in $content) {
                        if ($block.type -eq "tool_result" -and $block.is_error) {
                            $errorCount++
                            $toolCalls += "[ERROR] $($block.tool_use_id): $($block.content -replace '`n',' ' | Select-Object -First 200)"
                        }
                    }
                }
            }
            if ($entry.type -eq "assistant" -and $entry.message.usage) {
                $totalInputTokens += [int]($entry.message.usage.input_tokens -as [int])
                $totalOutputTokens += [int]($entry.message.usage.output_tokens -as [int])
                if ($entry.message.model) { $modelUsed = $entry.message.model }
            }
            if ($entry.message -and $entry.message.content) {
                foreach ($block in $entry.message.content) {
                    if ($block.type -eq "system" -and $block.text -match "compact") { $compactCount++ }
                }
            }
            if ($entry.type -eq "user" -and $entry.message.role -eq "user") {
                $promptText = ""
                if ($entry.message.content) {
                    foreach ($block in $entry.message.content) {
                        if ($block.type -eq "text") { $promptText += $block.text + " " }
                    }
                }
                if ($promptText.Trim()) { $userPrompts += $promptText.Trim() }
            }
        } catch { }
    }

    $summary = @"
=== SESSION TRANSCRIPT SUMMARY ===
Model: $modelUsed
Total errors: $errorCount
Total input tokens: $totalInputTokens
Total output tokens: $totalOutputTokens
Compaction events: $compactCount
Tool calls analyzed: $($toolCalls.Count)

=== USER PROMPTS ===
$($userPrompts -join "`n")

=== TOOL ERRORS ===
$(if ($toolCalls.Count -gt 0) { $toolCalls -join "`n" } else { "(none)" })

=== RAW TRANSCRIPT TAIL ($MAX_TRANSCRIPT_LINES lines) ===
$($rawLines -join "`n")
"@
    Write-Host "[vj-reflect] Summary: $errorCount errors, ${totalInputTokens} input tokens, ${totalOutputTokens} output tokens"
} catch {
    Write-Host "[vj-reflect] Failed to parse transcript: $_"
    exit 0
}

# Run reflection via claude -p
Write-Host "[vj-reflect] Running reflection..."
$claudePath = (Get-Command "claude" -ErrorAction SilentlyContinue).Source
if (-not $claudePath) {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Claude Code\claude.exe",
        "$env:APPDATA\npm\claude.cmd",
        "C:\Program Files\Claude Code\claude.exe"
    )
    foreach ($c in $candidates) { if (Test-Path $c) { $claudePath = $c; break } }
}
if (-not $claudePath) {
    Write-Host "[vj-reflect] claude CLI not found - skipping"
    exit 0
}

$reflectionPrompt = @'
You are a post-session reflection agent. Analyze this Claude Code session transcript and output ONLY valid JSON (no markdown, no backticks, no commentary).

Output exactly this schema:
{
  "quality_score": 0.0,
  "improvements": ["string", "string", ...],
  "rules": ["string", "string", ...]
}

quality_score: 0.0-1.0. 0.0-0.3 = critical failures, wasted tokens, ignored instructions. 0.4-0.6 = completed but with inefficiencies or errors. 0.7-0.8 = solid, minor improvements. 0.9-1.0 = exceptional.

improvements[]: 1-3 concrete, imperative suggestions for next session. Generalize - no specific filenames, URLs, or error messages.

rules[]: 0-3 reusable behavioral rules. Format as "Context: Rule". Must generalize to future sessions.

Never propose changes that would: place trades, modify private keys, bypass safety rules, or expose credentials.

Here is the transcript:
'@ + "`n`n$summary"

$env:VJ_REFLECTING = "1"
try {
    $promptFile = [System.IO.Path]::GetTempFileName() + ".txt"
    $reflectionPrompt | Out-File -FilePath $promptFile -Encoding UTF8 -NoNewline
    $promptContent = Get-Content -Path $promptFile -Raw
    $result = & $claudePath -p $promptContent --output-format text 2>&1
    Remove-Item $promptFile -Force -ErrorAction SilentlyContinue
} catch {
    Remove-Item $promptFile -Force -ErrorAction SilentlyContinue
    Write-Host "[vj-reflect] claude -p failed: $_"
    $env:VJ_REFLECTING = ""
    exit 0
}
$env:VJ_REFLECTING = ""
Write-Host "[vj-reflect] Reflection complete"

# Parse and validate
try {
    $cleaned = $result -replace '```json\s*', '' -replace '```\s*$', '' -replace '^```\s*', ''
    $cleaned = $cleaned.Trim()
    if ($cleaned -match '(\{[\s\S]*"quality_score"[\s\S]*\})') { $cleaned = $matches[1] }
    $reflection = $cleaned | ConvertFrom-Json
    $qs = [double]$reflection.quality_score
    $improvements = $reflection.improvements
    $rules = $reflection.rules
    if ($null -eq $qs) {
        Write-Host "[vj-reflect] quality_score missing - discarding"
        exit 0
    }
    Write-Host "[vj-reflect] Quality score: $qs"
    Write-Host "[vj-reflect] Improvements: $($improvements.Count), Rules: $($rules.Count)"
    if ($qs -lt $QUALITY_THRESHOLD) {
        Write-Host "[vj-reflect] Score below threshold ($QUALITY_THRESHOLD) - discarding"
        exit 0
    }
} catch {
    Write-Host "[vj-reflect] Failed to parse reflection JSON: $_"
    exit 0
}

# Append to lessons file
try {
    $lessonEntry = [ordered]@{
        timestamp    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
        session_id   = (Split-Path $TranscriptPath -Leaf) -replace '\.jsonl$', ''
        quality_score = $qs
        improvements = @($improvements)
        rules        = @($rules)
        model        = $modelUsed
        error_count  = $errorCount
        input_tokens = $totalInputTokens
        output_tokens = $totalOutputTokens
    } | ConvertTo-Json -Compress
    $lessonsDir = Split-Path $LESSONS_FILE -Parent
    if (-not (Test-Path $lessonsDir)) { New-Item -ItemType Directory -Path $lessonsDir -Force | Out-Null }
    Add-Content -Path $LESSONS_FILE -Value $lessonEntry -Encoding UTF8
    Write-Host "[vj-reflect] Lesson appended to $LESSONS_FILE"
} catch {
    Write-Host "[vj-reflect] Failed to write lessons file: $_"
    exit 0
}
Write-Host "[vj-reflect] Done - exit 0"
exit 0
