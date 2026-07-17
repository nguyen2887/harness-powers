# Initializes a project with the vendored repository-harness scaffold and the
# harness-powers pipeline: git init, merge-copy scaffold files, install
# harness-cli, create harness.db, wire canonical AGENTS.md plus the Claude import, and register hooks.
# Idempotent. Re-running REFRESHES harness-powers-owned artifacts (pipeline blocks
# between markers, vendored skills, the gate script) so a new plugin version lands
# without deleting anything by hand; your own files are never overwritten.
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

# Bump this when the vendored scaffold pins a new harness-cli version.
$HarnessCliTag = 'harness-cli-v0.1.11'
$HarnessCliReleaseBase = 'https://github.com/hoangnb24/repository-harness/releases/download'

function Detect-Platform {
    switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
        'X64'   { 'windows-x64' }
        'Arm64' { 'windows-arm64' }
        default { 'unsupported' }
    }
}

# Fetch the platform harness-cli into scripts\bin\harness-cli.exe when missing.
# Soft-fails (warns, never aborts) so init still completes offline.
function Ensure-CliBinary {
    $binDir = Join-Path $Directory 'scripts\bin'
    $target = Join-Path $binDir 'harness-cli.exe'
    if (Test-Path $target) { return }
    if (Test-Path (Join-Path $binDir 'harness-cli')) { return }

    $platform = Detect-Platform
    if ($platform -eq 'unsupported') {
        Write-Step "WARNING: unsupported platform ($([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)); cannot fetch harness-cli."
        return
    }

    $name = "harness-cli-$platform.exe"
    $url = "$HarnessCliReleaseBase/$HarnessCliTag/$name"

    if ($DryRun) {
        Write-Step "DRY RUN: would download $name ($HarnessCliTag) into scripts\bin\harness-cli.exe"
        return
    }

    New-Item -ItemType Directory -Force $binDir | Out-Null
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force $tmp | Out-Null
    $tmpBin = Join-Path $tmp $name
    Write-Step "Downloading $name ($HarnessCliTag)..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmpBin -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Step "WARNING: download failed ($url): $($_.Exception.Message)."
        Write-Step 'Fetch it manually into scripts\bin\harness-cli.exe and re-run.'
        Remove-Item -Recurse -Force $tmp; return
    }
    # Verify the checksum when the .sha256 is published alongside the binary.
    try {
        $shaTmp = "$tmpBin.sha256"
        Invoke-WebRequest -Uri "$url.sha256" -OutFile $shaTmp -UseBasicParsing -ErrorAction Stop
        $expected = (((Get-Content $shaTmp -Raw) -split '\s+') | Where-Object { $_ })[0]
        $actual = (Get-FileHash $tmpBin -Algorithm SHA256).Hash
        if ($expected -and $actual -and ($expected.ToLower() -ne $actual.ToLower())) {
            Write-Step "WARNING: checksum mismatch for $name (expected $expected, got $actual). Not installing."
            Remove-Item -Recurse -Force $tmp; return
        }
    } catch { }  # no checksum published -> skip verification
    Copy-Item $tmpBin $target -Force
    Remove-Item -Recurse -Force $tmp
    try {
        & $target --help *> $null
        Write-Step "Installed scripts\bin\harness-cli.exe ($platform)."
    } catch {
        Write-Step 'WARNING: downloaded harness-cli did not run cleanly; check the binary.'
    }
}

# Replace the harness-powers block between markers in $file with the template
# (which includes its own BEGIN/END markers), or append it if absent. Only the
# marked block is touched; everything else in the file is preserved verbatim.
function Upsert-Block($file, $template, $label) {
    $existing = if (Test-Path $file) { Get-Content $file -Raw } else { '' }
    $block = (Get-Content $template -Raw).TrimEnd("`r", "`n")
    $beginMarker = '<!-- HARNESS-POWERS:BEGIN -->'
    $endMarker   = '<!-- HARNESS-POWERS:END -->'
    $bi = $existing.IndexOf($beginMarker)
    $ei = $existing.IndexOf($endMarker)
    if ($bi -ge 0 -and $ei -ge 0) {
        if ($DryRun) { Write-Step "DRY RUN: would refresh harness-powers block in $label"; return }
        $before = $existing.Substring(0, $bi)
        $after  = $existing.Substring($ei + $endMarker.Length)
        Set-Content -Path $file -Value ($before + $block + $after) -NoNewline
        Write-Step "Refreshed harness-powers block in $label."
    } elseif ($DryRun) {
        Write-Step "DRY RUN: would append harness-powers block to $label"
    } else {
        $sep = if ($existing -and -not $existing.EndsWith("`n")) { "`n`n" } elseif ($existing) { "`n" } else { '' }
        Set-Content -Path $file -Value ($existing + $sep + $block) -NoNewline
        Write-Step "Appended harness-powers block to $label."
    }
}

function Ensure-ClaudeShim {
    $file = Join-Path $Directory 'CLAUDE.md'
    if (Test-Path $file) {
        $nonBlank = @(Get-Content $file | Where-Object { $_.Trim() })
        if ($nonBlank.Count -eq 1 -and $nonBlank[0].Trim() -eq '@AGENTS.md') {
            Write-Step 'CLAUDE.md already imports canonical AGENTS.md.'
            return
        }
    }
    if ($DryRun) {
        Write-Step 'DRY RUN: would install @AGENTS.md Claude import shim'
        return
    }
    if (-not (Test-Path $file)) {
        Set-Content -Path $file -Value '@AGENTS.md'
        Write-Step 'Installed CLAUDE.md -> @AGENTS.md import shim.'
        return
    }

    $existing = Get-Content $file -Raw
    $cleaned = [regex]::Replace(
        $existing,
        '(?s)<!-- HARNESS-POWERS:BEGIN -->.*?<!-- HARNESS-POWERS:END -->',
        ''
    ).Trim()
    if (-not $cleaned) {
        Set-Content -Path $file -Value '@AGENTS.md'
        Write-Step 'Replaced legacy owned CLAUDE.md block with @AGENTS.md import shim.'
    } else {
        if ($cleaned -notmatch '(?m)^@AGENTS\.md\s*$') {
            $cleaned = "@AGENTS.md`n`n$cleaned"
        }
        Set-Content -Path $file -Value $cleaned
        Write-Step 'WARNING: preserved custom CLAUDE.md content after @AGENTS.md; migrate it into AGENTS.md to reach the one-line canonical setup.'
    }
}

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

# --- 2b. Portable runtime skills -----------------------------------------------
# Overwritten on re-init so a new plugin version refreshes only
# harness-powers-owned skill directories.
$portableSkills = Join-Path $root 'portable-skills'
if (Test-Path $portableSkills) {
    $skN = 0
    $legacyN = 0
    Get-ChildItem $portableSkills -Directory | ForEach-Object {
        $name = $_.Name
        foreach ($legacyBase in @('.codex/skills', '.grok/skills')) {
            $legacyDir = Join-Path $Directory (Join-Path $legacyBase $name)
            if (Test-Path $legacyDir) {
                $skillFile = Join-Path $legacyDir 'SKILL.md'
                $isHarnessOwned = (Test-Path $skillFile) -and [bool](Select-String -Path $skillFile -Pattern 'Harness|harness-powers|\.harness-powers|durable mailbox' -Quiet)
                if (-not $isHarnessOwned) {
                    Write-Step "WARNING: preserving unrecognized $legacyBase/$name; it may shadow the shared Harness skill."
                } else {
                    $legacyN++
                    if (-not $DryRun) { Remove-Item -Recurse -Force $legacyDir }
                }
            }
        }
        foreach ($base in @('.agents/skills', '.claude/skills')) {
            $dest = Join-Path $Directory (Join-Path $base $name)
            if ($DryRun) {
                $skN++
            } else {
                New-Item -ItemType Directory -Force $dest | Out-Null
                Copy-Item (Join-Path $_.FullName '*') $dest -Recurse -Force
                $skN++
            }
        }
    }
    Write-Step "Portable skills: $skN vendored/refreshed across runtime adapters; $legacyN redundant .codex/.grok skill dir(s) removed."
}

# --- 2c. Role/stage workflow reference (harness-powers-owned) ------------------
$workflowSrc = Join-Path $scaffold 'docs/AGENT_WORKFLOW.md'
$workflowDest = Join-Path $Directory 'docs/AGENT_WORKFLOW.md'
if (Test-Path $workflowSrc) {
    if ($DryRun) {
        Write-Step 'DRY RUN: would install/refresh docs/AGENT_WORKFLOW.md'
    } else {
        New-Item -ItemType Directory -Force (Split-Path $workflowDest) | Out-Null
        Copy-Item $workflowSrc $workflowDest -Force
        Write-Step 'Installed/refreshed docs/AGENT_WORKFLOW.md.'
    }
}

# --- 2d. Remove legacy harness-powers.toml -------------------------------------
# Older installs vendored a harness-powers.toml that bound workflow roles to
# runtime choices. The durable role resolver replaces it. Delete OUR copy
# (identified by its header); leave unrelated files.
$legacyToml = Join-Path $Directory 'harness-powers.toml'
if ((Test-Path $legacyToml) -and ((Get-Content $legacyToml -TotalCount 3) -match 'harness-powers')) {
    if ($DryRun) {
        Write-Step 'DRY RUN: would remove legacy harness-powers.toml (obsolete model-hints file).'
    } else {
        Remove-Item -Force $legacyToml
        Write-Step 'Removed legacy harness-powers.toml (obsolete runtime bindings).'
    }
}

# --- 3. harness-cli + database -------------------------------------------------
Ensure-CliBinary
$cli = Join-Path $Directory 'scripts\bin\harness-cli.exe'
if (-not (Test-Path $cli)) { $cli = Join-Path $Directory 'scripts/bin/harness-cli' }
if ((-not (Test-Path $cli)) -and $DryRun) {
    Write-Step 'DRY RUN: harness-cli not present yet; would download it, then run harness-cli init.'
} elseif (-not (Test-Path $cli)) {
    Write-Step 'WARNING: no runnable harness-cli (auto-download failed or offline; see warnings above).'
    Write-Step "Fetch the $HarnessCliTag binary from https://github.com/hoangnb24/repository-harness/releases into scripts\bin\harness-cli.exe and re-run."
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

# --- 4. AGENTS.md is canonical; CLAUDE.md imports it ---------------------------
Upsert-Block (Join-Path $Directory 'AGENTS.md') (Join-Path $templates 'agents-md-block.md') 'AGENTS.md'
Ensure-ClaudeShim

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

# --- 6. Shared mailbox helper + hard-gate adapters -----------------------------
$gateSrc = Join-Path $root 'gate'
if (Test-Path $gateSrc) {
    $gateBin = Join-Path $Directory '.harness-powers/bin/harness-powers-gate'
    $workflowBin = Join-Path $Directory '.harness-powers/bin/harness-powers-workflow'
    $doctorBin = Join-Path $Directory '.harness-powers/bin/harness-powers-doctor'
    if ($DryRun) {
        Write-Step 'DRY RUN: would install/refresh mailbox helper and hard gate'
    } else {
        New-Item -ItemType Directory -Force (Split-Path $gateBin) | Out-Null
        Copy-Item (Join-Path $gateSrc 'harness-powers-gate') $gateBin -Force
        Copy-Item (Join-Path $gateSrc 'harness-powers-workflow') $workflowBin -Force
        Copy-Item (Join-Path $gateSrc 'harness-powers-doctor') $doctorBin -Force
        Write-Step 'Installed/refreshed mailbox helper, doctor, and hard gate.'
    }

    function Install-Hook($srcRel, $destRel, $label) {
        $src = Join-Path $gateSrc $srcRel
        $dest = Join-Path $Directory $destRel
        if (Test-Path $dest) {
            Write-Step "$label hook config exists at $destRel - left as is; add the gate hook manually if you want it there."
        } elseif ($DryRun) {
            Write-Step "DRY RUN: would write $destRel ($label gate hook)"
        } else {
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Copy-Item $src $dest -Force
            Write-Step "Wired $label gate hook -> $destRel"
        }
    }
    Install-Hook 'hooks/codex-hooks.json'     '.codex/hooks.json'               'Codex'
    Install-Hook 'hooks/grok-hooks.json'      '.grok/hooks/harness-powers.json' 'Grok'
    Install-Hook 'hooks/claude-settings.json' '.claude/settings.json'           'Claude Code'

    if (-not $DryRun) {
        Write-Step 'Hard-gate active: code edits for active normal/high-risk tasks require a "plan-review passed:" reviewer approval; dormant planned roadmap stories are ignored.'
        Write-Step 'TRUST REQUIRED: in Codex and Grok run "/hooks-trust" (or launch with --trust) once, or project hooks will NOT execute. On Windows the hook needs bash (git-bash/WSL).'
    }
}

Write-Step "Init complete. Start a fresh session, then use 'work <description>' or its runtime adapter."
