# Installs the harness-powers workflow into a target repo that already has the
# repository-harness scaffold: appends the CLAUDE.md bootstrap block, patches
# docs/TRACE_SPEC.md with the lean trace profile, and registers external
# review/explore tools in the harness tool registry when their CLIs are present.
param(
    [string]$Directory = (Get-Location).Path,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$templates = Join-Path $PSScriptRoot '..\templates'

function Write-Step($msg) { Write-Host "[harness-powers] $msg" }

# --- 0. Preconditions -------------------------------------------------------
$Directory = (Resolve-Path $Directory).Path
$cli = Join-Path $Directory 'scripts\bin\harness-cli.exe'
if (-not (Test-Path $cli)) { $cli = Join-Path $Directory 'scripts/bin/harness-cli' }
if (-not (Test-Path $cli)) {
    throw "No Harness scaffold found at $Directory (scripts/bin/harness-cli missing). Install repository-harness first."
}
Write-Step "Target repo: $Directory"

# --- 1. CLAUDE.md bootstrap block -------------------------------------------
$claudeMd = Join-Path $Directory 'CLAUDE.md'
$block = Get-Content (Join-Path $templates 'claude-md-block.md') -Raw
$existing = if (Test-Path $claudeMd) { Get-Content $claudeMd -Raw } else { '' }

if ($existing -match 'HARNESS-POWERS:BEGIN') {
    Write-Step 'CLAUDE.md already has the harness-powers block. Skipped.'
} elseif ($DryRun) {
    Write-Step 'DRY RUN: would append harness-powers block to CLAUDE.md'
} else {
    $sep = if ($existing -and -not $existing.EndsWith("`n")) { "`n`n" } elseif ($existing) { "`n" } else { '' }
    Set-Content -Path $claudeMd -Value ($existing + $sep + $block) -NoNewline
    Write-Step 'Appended harness-powers block to CLAUDE.md'
}

# --- 2. TRACE_SPEC.md lean profile note --------------------------------------
$traceSpec = Join-Path $Directory 'docs\TRACE_SPEC.md'
if (Test-Path $traceSpec) {
    $spec = Get-Content $traceSpec -Raw
    if ($spec -match 'HARNESS-POWERS:LEAN-TRACE:BEGIN') {
        Write-Step 'TRACE_SPEC.md already has the lean profile note. Skipped.'
    } elseif ($DryRun) {
        Write-Step 'DRY RUN: would append lean trace profile note to docs/TRACE_SPEC.md'
    } else {
        $note = Get-Content (Join-Path $templates 'trace-spec-lean-block.md') -Raw
        Add-Content -Path $traceSpec -Value "`n$note"
        Write-Step 'Appended lean trace profile note to docs/TRACE_SPEC.md'
    }
} else {
    Write-Step 'docs/TRACE_SPEC.md not found. Skipped lean profile note.'
}

# --- 3. Tool registry: external-review / repo-explore ------------------------
function Register-HarnessTool($name, $capability, $responsibility, $description) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Step "CLI '$name' not on PATH. Skipped registration (register later with: harness-cli tool register)."
        return
    }
    if ($DryRun) { Write-Step "DRY RUN: would register '$name' as capability '$capability'"; return }
    try {
        & $cli tool register --name $name --kind cli --capability $capability `
            --command $name --description $description --responsibility $responsibility 2>&1 | ForEach-Object {
            Write-Step "  $_"
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Step "Registered '$name' -> $capability"
        } else {
            Write-Step "Registration of '$name' failed or already exists. Continuing."
        }
    } catch {
        Write-Step "Registration of '$name' errored: $($_.Exception.Message). Continuing."
    }
}

Push-Location $Directory
try {
    Register-HarnessTool 'codex' 'external-review' 'Verification' 'GPT reviewer via Codex CLI for plan-review and code-review gates'
    Register-HarnessTool 'agy' 'repo-explore' 'Context selection' 'Gemini explorer via Antigravity CLI for wide repo scans'
    if (-not $DryRun) {
        try { & $cli tool check 2>&1 | ForEach-Object { Write-Step "  $_" } }
        catch { Write-Step "tool check errored: $($_.Exception.Message). Continuing." }
    }
} finally {
    Pop-Location
}

Write-Step 'Done. Open a fresh Claude Code session in the target repo to activate the pipeline.'
