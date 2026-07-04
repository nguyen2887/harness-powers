# Initializes a project with the vendored repository-harness scaffold and the
# harness-powers pipeline: git init, merge-copy scaffold files, install
# harness-cli, create harness.db, wire CLAUDE.md, register external tools.
# Idempotent and merge-safe: existing files are never overwritten.
param(
    [string]$Directory = (Get-Location).Path,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$scaffold = Join-Path $root 'scaffold'
$templates = Join-Path $root 'templates'

function Write-Step($msg) { Write-Host "[harness-powers] $msg" }

$Directory = (Resolve-Path $Directory).Path
Write-Step "Target project: $Directory"

# --- 1. git init --------------------------------------------------------------
if (Test-Path (Join-Path $Directory '.git')) {
    Write-Step 'Git repository already present.'
} elseif ($DryRun) {
    Write-Step 'DRY RUN: would git init'
} else {
    git -C $Directory init | Out-Null
    Write-Step 'Initialized git repository.'
}

# --- 2. Merge-copy scaffold ----------------------------------------------------
$created = 0; $skipped = 0
Get-ChildItem $scaffold -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($scaffold.Length + 1)
    # The root gitignore is stored without its dot so it stays inert inside the plugin repo.
    if ($rel -eq 'gitignore') { $rel = '.gitignore' }
    $dest = Join-Path $Directory $rel
    if (Test-Path $dest) {
        $skipped++
    } elseif ($DryRun) {
        $created++
    } else {
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Copy-Item $_.FullName $dest
        $created++
    }
}
$verb = if ($DryRun) { 'DRY RUN: would copy' } else { 'Scaffold:' }
Write-Step "$verb $created file(s) created, $skipped already present (skipped)."

# --- 3. harness-cli + database -------------------------------------------------
$cli = Join-Path $Directory 'scripts\bin\harness-cli.exe'
if (-not (Test-Path $cli)) { $cli = Join-Path $Directory 'scripts/bin/harness-cli' }
if (-not (Test-Path $cli)) {
    Write-Step 'WARNING: no harness-cli binary for this platform. Only windows-x64 is vendored.'
    Write-Step 'Download your platform binary from https://github.com/hoangnb24/repository-harness/releases into scripts/bin/ and re-run.'
} elseif (Test-Path (Join-Path $Directory 'harness.db')) {
    Write-Step 'harness.db already present.'
} elseif ($DryRun) {
    Write-Step 'DRY RUN: would run harness-cli init'
} else {
    Push-Location $Directory
    try { & $cli init 2>&1 | ForEach-Object { Write-Step "  $_" } }
    finally { Pop-Location }
    Write-Step 'Initialized harness.db.'
}

# --- 4. CLAUDE.md pipeline block ------------------------------------------------
$claudeMd = Join-Path $Directory 'CLAUDE.md'
$existing = if (Test-Path $claudeMd) { Get-Content $claudeMd -Raw } else { '' }
if ($existing -match 'HARNESS-POWERS:BEGIN') {
    Write-Step 'CLAUDE.md already has the harness-powers block.'
} elseif ($DryRun) {
    Write-Step 'DRY RUN: would append harness-powers block to CLAUDE.md'
} else {
    $block = Get-Content (Join-Path $templates 'claude-md-block.md') -Raw
    $sep = if ($existing -and -not $existing.EndsWith("`n")) { "`n`n" } elseif ($existing) { "`n" } else { '' }
    Set-Content -Path $claudeMd -Value ($existing + $sep + $block) -NoNewline
    Write-Step 'Appended harness-powers block to CLAUDE.md.'
}

# --- 5. Lean trace profile note (covers pre-existing harness repos) --------------
$traceSpec = Join-Path $Directory 'docs\TRACE_SPEC.md'
if (Test-Path $traceSpec) {
    $spec = Get-Content $traceSpec -Raw
    if ($spec -match 'HARNESS-POWERS:LEAN-TRACE:BEGIN') {
        Write-Step 'TRACE_SPEC.md already has the lean profile note.'
    } elseif ($DryRun) {
        Write-Step 'DRY RUN: would append lean trace note to docs/TRACE_SPEC.md'
    } else {
        $note = Get-Content (Join-Path $templates 'trace-spec-lean-block.md') -Raw
        Add-Content -Path $traceSpec -Value "`n$note"
        Write-Step 'Appended lean trace profile note to docs/TRACE_SPEC.md.'
    }
}

# --- 6. Tool registry: external-review / repo-explore ----------------------------
function Register-HarnessTool($name, $capability, $responsibility, $description) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Step "CLI '$name' not on PATH. Skipped registration."
        return
    }
    # Register the resolved path: the Rust CLI's PATH probe does not apply
    # PATHEXT on Windows, so a bare name like 'codex' fails its existence check.
    if ($DryRun) { Write-Step "DRY RUN: would register '$name' ($($cmd.Source)) as '$capability'"; return }
    try {
        & $cli tool register --name $name --kind cli --capability $capability `
            --command $cmd.Source --description $description --responsibility $responsibility 2>&1 | ForEach-Object {
            Write-Step "  $_"
        }
        if ($LASTEXITCODE -eq 0) { Write-Step "Registered '$name' -> $capability" }
        else { Write-Step "Registration of '$name' failed or already exists. Continuing." }
    } catch {
        Write-Step "Registration of '$name' errored: $($_.Exception.Message). Continuing."
    }
}

if (Test-Path $cli) {
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
}

Write-Step 'Init complete. Commit the scaffold, then start a fresh session (the CLAUDE.md block loads at session start).'
