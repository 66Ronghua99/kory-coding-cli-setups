param(
    [switch]$DryRun,
    [switch]$SyncCodexConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetHome = if ($env:SYNC_HOME) { $env:SYNC_HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { throw "USERPROFILE is not set." }
$SuperpowersDir = if ($env:SUPERPOWERS_DIR) { $env:SUPERPOWERS_DIR } else { Join-Path $SourceDir "superpowers" }
$SuperpowersRemoteUrl = if ($env:SUPERPOWERS_REMOTE_URL) { $env:SUPERPOWERS_REMOTE_URL } else { "https://github.com/obra/superpowers.git" }
$SuperpowersBranch = if ($env:SUPERPOWERS_BRANCH) { $env:SUPERPOWERS_BRANCH } else { "main" }
$HumanizeSync = if ($env:HUMANIZE_SYNC) { $env:HUMANIZE_SYNC } else { "1" }
$HumanizeDir = if ($env:HUMANIZE_DIR) { $env:HUMANIZE_DIR } else { Join-Path $SourceDir "humanize" }
$HumanizeRemoteUrl = if ($env:HUMANIZE_REMOTE_URL) { $env:HUMANIZE_REMOTE_URL } else { "https://github.com/PolyArch/humanize.git" }
$HumanizeBranch = if ($env:HUMANIZE_BRANCH) { $env:HUMANIZE_BRANCH } else { "main" }
$KimiCodeHome = if ($env:KIMI_CODE_HOME) { $env:KIMI_CODE_HOME } else { Join-Path $TargetHome ".kimi-code" }
$BackupRoot = Join-Path $TargetHome (".coding-cli-sync-backups\" + (Get-Date -Format "yyyyMMdd_HHmmss"))
$CuratedSuperpowersSkills = @(
    "using-superpowers",
    "brainstorming",
    "writing-plans",
    "executing-plans",
    "test-driven-development",
    "verification-before-completion"
)
$DeprecatedCodexSkills = @(
    "harness-lint-test-design",
    "harness-refactor"
)

function Log {
    param([string]$Message)
    Write-Host $Message
}

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    if ($DryRun) {
        Write-Host "[dry-run] $Label"
        return
    }

    & $Action
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Invoke-Step "mkdir $Path" { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
    }
}

function Normalize-ComparablePath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
    } catch {
        $fullPath = [string]$Path
    }

    return $fullPath.TrimEnd('\', '/').ToLowerInvariant()
}

function Get-BackupRelativePath {
    param([string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($root)) {
        return $fullPath.TrimStart('\', '/')
    }

    $rootLabel = ($root -replace '[:\\\/]+', '').Trim()
    if ([string]::IsNullOrWhiteSpace($rootLabel)) {
        $rootLabel = "root"
    }

    $relative = $fullPath.Substring($root.Length).TrimStart('\', '/')
    if ([string]::IsNullOrWhiteSpace($relative)) {
        return $rootLabel
    }

    return Join-Path $rootLabel $relative
}

function Test-SameVolume {
    param(
        [string]$LeftPath,
        [string]$RightPath
    )

    $leftRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($LeftPath))
    $rightRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($RightPath))
    return [string]::Equals($leftRoot, $rightRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-PathOrLink {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        return $true
    }

    try {
        Get-Item -LiteralPath $Path -Force -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Backup-Path {
    param([string]$Target)

    if (Test-PathOrLink $Target) {
        Ensure-Dir $BackupRoot
        $relative = Get-BackupRelativePath $Target
        $backupTarget = Join-Path $BackupRoot $relative
        Ensure-Dir (Split-Path -Parent $backupTarget)
        Invoke-Step "move $Target -> $backupTarget" { Move-Item -LiteralPath $Target -Destination $backupTarget }
        Log "Backed up $Target -> $backupTarget"
    }
}

function Get-LinkTargets {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $item = Get-Item -LiteralPath $Path -Force
    $linkTypeProperty = $item.PSObject.Properties["LinkType"]
    if ($null -ne $linkTypeProperty -and $linkTypeProperty.Value -eq "HardLink") {
        $targetProperty = $item.PSObject.Properties["Target"]
        if ($null -ne $targetProperty) {
            $target = $targetProperty.Value
            if ($target -is [System.Array]) {
                return @($target | ForEach-Object { [string]$_ })
            }
            if ($null -ne $target) {
                return @([string]$target)
            }
        }
    }

    $linkTargetProperty = $item.PSObject.Properties["LinkTarget"]
    if ($null -ne $linkTargetProperty) {
        $linkTarget = $linkTargetProperty.Value
        if ($linkTarget -is [System.Array]) {
            return @($linkTarget | ForEach-Object { [string]$_ })
        }
        return @([string]$linkTarget)
    }

    $targetProperty = $item.PSObject.Properties["Target"]
    if ($null -ne $targetProperty) {
        $target = $targetProperty.Value
        if ($target -is [System.Array]) {
            return @($target | ForEach-Object { [string]$_ })
        }
        if ($null -ne $target) {
            return @([string]$target)
        }
    }

    return @()
}

function Ensure-FileSymlink {
    param(
        [string]$Source,
        [string]$Target
    )

    Ensure-Dir (Split-Path -Parent $Target)

    $normalizedSource = Normalize-ComparablePath $Source
    $currentTargets = @(Get-LinkTargets $Target | ForEach-Object { Normalize-ComparablePath $_ })
    if ($currentTargets -contains $normalizedSource) {
        Log "OK file link: $Target -> $Source"
        return
    }

    if ((Test-Path -LiteralPath $Source -PathType Leaf) -and (Test-Path -LiteralPath $Target -PathType Leaf)) {
        $sourceHash = (Get-FileHash -LiteralPath $Source).Hash
        $targetHash = (Get-FileHash -LiteralPath $Target).Hash
        if ($sourceHash -eq $targetHash) {
            Log "OK file sync: $Target matches $Source"
            return
        }
    }

    if (Test-Path -LiteralPath $Target) {
        Backup-Path $Target
    }

    try {
        Invoke-Step "file symlink $Target -> $Source" {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
        }
    } catch {
        if (-not (Test-SameVolume -LeftPath $Source -RightPath $Target)) {
            throw
        }

        Invoke-Step "hardlink $Target -> $Source" {
            New-Item -ItemType HardLink -Path $Target -Target $Source | Out-Null
        }
    }

    Log "Linked $Target -> $Source"
}

function Ensure-DirectoryLink {
    param(
        [string]$Source,
        [string]$Target
    )

    Ensure-Dir (Split-Path -Parent $Target)

    $normalizedSource = Normalize-ComparablePath $Source
    $currentTargets = @(Get-LinkTargets $Target | ForEach-Object { Normalize-ComparablePath $_ })
    if ($currentTargets -contains $normalizedSource) {
        Log "OK directory link: $Target -> $Source"
        return
    }

    if (Test-Path -LiteralPath $Target) {
        Backup-Path $Target
    }

    try {
        Invoke-Step "directory symlink $Target -> $Source" {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
        }
    } catch {
        Invoke-Step "junction $Target -> $Source" {
            cmd /c "mklink /J `"$Target`" `"$Source`"" | Out-Null
        }
    }

    Log "Linked $Target -> $Source"
}

function Ensure-SuperpowersRepo {
    if ([string]::IsNullOrWhiteSpace($SuperpowersRemoteUrl)) {
        throw "Missing superpowers remote. Set SUPERPOWERS_REMOTE_URL or restore the default."
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git is required to sync superpowers"
    }

    if (-not (Test-Path -LiteralPath $SuperpowersDir)) {
        Ensure-Dir (Split-Path -Parent $SuperpowersDir)
        Invoke-Step "git clone $SuperpowersRemoteUrl -> $SuperpowersDir" {
            git clone --branch $SuperpowersBranch --single-branch $SuperpowersRemoteUrl $SuperpowersDir | Out-Null
        }
    } elseif (-not (Test-Path -LiteralPath (Join-Path $SuperpowersDir ".git"))) {
        throw "Existing superpowers path is not a git repository: $SuperpowersDir"
    } else {
        Invoke-Step "git checkout $SuperpowersBranch in $SuperpowersDir" {
            git -C $SuperpowersDir checkout $SuperpowersBranch | Out-Null
        }
        Invoke-Step "git pull --ff-only origin $SuperpowersBranch in $SuperpowersDir" {
            git -C $SuperpowersDir pull --ff-only origin $SuperpowersBranch | Out-Null
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $SuperpowersDir "skills") -PathType Container)) {
        throw "Missing superpowers skills directory: $SuperpowersDir\skills."
    }
}

function Invoke-NativeChecked {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    Invoke-Step $Label {
        & $Action
        if ($LASTEXITCODE -ne 0) {
            throw "$Label failed with exit code $LASTEXITCODE"
        }
    }
}

function Ensure-HumanizeRepo {
    if ($HumanizeSync -eq "0") {
        return
    }

    if ([string]::IsNullOrWhiteSpace($HumanizeRemoteUrl)) {
        throw "Missing Humanize remote. Set HUMANIZE_REMOTE_URL or HUMANIZE_SYNC=0."
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git is required to sync humanize"
    }

    if (-not (Test-Path -LiteralPath $HumanizeDir)) {
        Ensure-Dir (Split-Path -Parent $HumanizeDir)
        Invoke-NativeChecked "git clone $HumanizeRemoteUrl -> $HumanizeDir" {
            git clone --branch $HumanizeBranch --single-branch $HumanizeRemoteUrl $HumanizeDir | Out-Null
        }
        if ($DryRun) {
            return
        }
    } elseif (-not (Test-Path -LiteralPath (Join-Path $HumanizeDir ".git"))) {
        throw "Existing humanize path is not a git repository: $HumanizeDir"
    } else {
        $hooksInstaller = Join-Path (Join-Path $HumanizeDir "scripts") "install-codex-hooks.sh"
        if (Test-Path -LiteralPath $hooksInstaller -PathType Leaf) {
            Invoke-NativeChecked "restore managed Humanize hook installer in $HumanizeDir" {
                git -C $HumanizeDir checkout -- scripts/install-codex-hooks.sh | Out-Null
            }
        }
        Invoke-NativeChecked "git checkout $HumanizeBranch in $HumanizeDir" {
            git -C $HumanizeDir checkout $HumanizeBranch | Out-Null
        }
        Invoke-NativeChecked "git pull --ff-only origin $HumanizeBranch in $HumanizeDir" {
            git -C $HumanizeDir pull --ff-only origin $HumanizeBranch | Out-Null
        }
    }

    $installer = Join-Path (Join-Path $HumanizeDir "scripts") "install-skill.sh"
    if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
        throw "Missing Humanize installer: $installer"
    }
}

function Repair-HumanizeCodexHookProbe {
    if ($HumanizeSync -eq "0") {
        return
    }

    $hooksInstaller = Join-Path (Join-Path $HumanizeDir "scripts") "install-codex-hooks.sh"
    if (-not (Test-Path -LiteralPath $hooksInstaller -PathType Leaf)) {
        return
    }

    $oldProbe = "codex features list 2>/dev/null | grep -qE '^codex_hooks[[:space:]]'"
    $content = Get-Content -LiteralPath $hooksInstaller -Raw
    if (-not $content.Contains($oldProbe)) {
        return
    }

    if ($DryRun) {
        Write-Host "[dry-run] patch Humanize codex_hooks feature probe in $hooksInstaller"
        return
    }

    $newProbe = "codex features list 2>/dev/null | awk '`$1 == `"codex_hooks`" { found = 1 } END { exit(found ? 0 : 1) }'"
    $content = $content.Replace($oldProbe, $newProbe)
    Set-Content -LiteralPath $hooksInstaller -Value $content -NoNewline
    Log "Patched Humanize codex_hooks feature probe: $hooksInstaller"
}

function Repair-HumanizeCodexHooksFeatureName {
    if ($HumanizeSync -eq "0") {
        return
    }

    $hooksInstaller = Join-Path (Join-Path $HumanizeDir "scripts") "install-codex-hooks.sh"
    if (-not (Test-Path -LiteralPath $hooksInstaller -PathType Leaf)) {
        return
    }

    $featureName = ""
    if (Get-Command codex -ErrorAction SilentlyContinue) {
        $features = codex features list 2>$null
        if ($features -match "^hooks\s") {
            $featureName = "hooks"
        } elseif ($features -match "^codex_hooks\s") {
            $featureName = "codex_hooks"
        }
    }

    if ($featureName -eq "") {
        return
    }

    if ($DryRun) {
        Write-Host "[dry-run] patch Humanize codex_hooks feature name to $featureName in $hooksInstaller"
        return
    }

    $content = Get-Content -LiteralPath $hooksInstaller -Raw
    if ($content.Contains("codex_hooks")) {
        $content = $content.Replace("codex_hooks", $featureName)
        Set-Content -LiteralPath $hooksInstaller -Value $content -NoNewline
        Log "Patched Humanize codex_hooks feature name to $featureName: $hooksInstaller"
    }
}

function Install-HumanizeRlcr {
    if ($HumanizeSync -eq "0") {
        return
    }

    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        throw "bash is required to run Humanize's installer. Install bash or set HUMANIZE_SYNC=0."
    }

    $installer = Join-Path (Join-Path $HumanizeDir "scripts") "install-skill.sh"
    $oldHome = $env:HOME
    $oldCodexHome = $env:CODEX_HOME
    try {
        $env:HOME = $TargetHome
        $env:CODEX_HOME = Join-Path $TargetHome ".codex"
        $sharedSkillsDir = Join-Path $SourceDir "skills"
        Invoke-NativeChecked "Humanize RLCR install" {
            bash $installer --target both --kimi-skills-dir "$sharedSkillsDir" --codex-skills-dir "$sharedSkillsDir"
        }
    } finally {
        if ($null -eq $oldHome) {
            Remove-Item Env:\HOME -ErrorAction SilentlyContinue
        } else {
            $env:HOME = $oldHome
        }

        if ($null -eq $oldCodexHome) {
            Remove-Item Env:\CODEX_HOME -ErrorAction SilentlyContinue
        } else {
            $env:CODEX_HOME = $oldCodexHome
        }
    }

    Repair-CodexHooksConfig
}

function Repair-CodexHooksConfig {
    if ($HumanizeSync -eq "0") {
        return
    }

    $hooksFile = Join-Path $TargetHome ".codex\hooks.json"
    if (-not (Test-Path -LiteralPath $hooksFile -PathType Leaf)) {
        return
    }

    if ($DryRun) {
        Write-Host "[dry-run] remove unsupported top-level description from $hooksFile"
        return
    }

    $json = Get-Content -LiteralPath $hooksFile -Raw | ConvertFrom-Json
    if ($json.PSObject.Properties.Name -contains "description") {
        $json.PSObject.Properties.Remove("description")
        $json | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $hooksFile
    }
}

function Install-KimiStopHookWrapper {
    if ($HumanizeSync -eq "0") {
        return
    }

    $hooksDir = Join-Path (Join-Path (Join-Path $SourceDir "skills") "humanize") "hooks"
    $wrapper = Join-Path $hooksDir "loop-kimi-stop-hook.sh"

    if ($DryRun) {
        Write-Host "[dry-run] install Kimi Stop hook wrapper: $wrapper"
        return
    }

    Ensure-Dir $hooksDir

    $wrapperContent = @'
#!/usr/bin/env bash
#
# Kimi native Stop hook adapter for Humanize RLCR.
#
# Kimi passes the hook event as JSON via stdin and expects:
#   exit 0  -> allow the stop
#   exit 2  -> block the stop (stderr is shown as the reason)
#
# Humanize's loop-codex-stop-hook.sh speaks the Claude Code hook protocol:
#   stdout contains JSON {"decision": "block", "reason": "..."} and exits 0.
# This wrapper converts between the two protocols.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CODEX_STOP_HOOK="$SCRIPT_DIR/loop-codex-stop-hook.sh"

TMP_OUTPUT="$(mktemp)"
trap 'rm -f "$TMP_OUTPUT"' EXIT

# The Codex/Claude hook reads stdin itself (it expects Claude-style hook JSON).
# It writes its decision JSON to stdout; we capture stdout while letting stderr
# flow through to Kimi so progress/review output is visible.
if ! "$CODEX_STOP_HOOK" >"$TMP_OUTPUT"; then
  echo "Humanize stop hook failed with exit code $?. Blocking exit." >&2
  exit 2
fi

# Parse the Claude-style decision from stdout.
DECISION=""
REASON=""
if command -v jq >/dev/null 2>&1; then
  DECISION="$(jq -r '.decision // empty' "$TMP_OUTPUT" 2>/dev/null || echo "")"
  REASON="$(jq -r '.reason // "Blocked by Humanize RLCR stop hook."' "$TMP_OUTPUT" 2>/dev/null || echo "Blocked by Humanize RLCR stop hook.")"
else
  # Minimal fallback if jq is missing: grep for the decision field.
  DECISION="$(grep -o '"decision"[[:space:]]*:[[:space:]]*"[^"]*"' "$TMP_OUTPUT" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || echo "")"
  REASON="Blocked by Humanize RLCR stop hook."
fi

if [[ "$DECISION" == "block" ]]; then
  echo "$REASON" >&2
  exit 2
fi

exit 0
'@

    Set-Content -LiteralPath $wrapper -Value $wrapperContent -NoNewline
    Log "Installed Kimi Stop hook wrapper: $wrapper"
}

function Ensure-KimiStopHookConfig {
    if ($HumanizeSync -eq "0") {
        return
    }

    $kimiConfig = Join-Path $KimiCodeHome "config.toml"
    $wrapper = Join-Path (Join-Path (Join-Path $SourceDir "skills") "humanize") "hooks\loop-kimi-stop-hook.sh"

    Ensure-Dir (Split-Path -Parent $kimiConfig)

    if ($DryRun) {
        Write-Host "[dry-run] ensure Kimi Stop hook config in $kimiConfig"
        return
    }

    if (-not (Get-Command python3 -ErrorAction SilentlyContinue)) {
        throw "python3 is required to update Kimi config"
    }

    $pythonScript = @"
import pathlib
import sys

try:
    import tomllib
except ImportError:
    import tomli as tomllib
import toml

config_path = pathlib.Path(sys.argv[1])
hook_command = sys.argv[2]

data = {}
if config_path.exists():
    data = tomllib.loads(config_path.read_text(encoding="utf-8"))

hooks = data.setdefault("hooks", [])

already_registered = any(
    isinstance(h, dict) and h.get("event") == "Stop" and h.get("command") == hook_command
    for h in hooks
)

if not already_registered:
    hooks.append({
        "event": "Stop",
        "command": hook_command,
        "timeout": 600,
    })
    config_path.write_text(toml.dumps(data), encoding="utf-8")
"@

    python3 -c $pythonScript $kimiConfig $wrapper
    Log "Added Kimi Stop hook config: $kimiConfig"
}

function Cleanup-LegacySuperpowersNamespace {
    $legacyPath = Join-Path (Join-Path $SourceDir "skills") "superpowers"
    if (Test-Path -LiteralPath $legacyPath) {
        Backup-Path $legacyPath
    }
}

function Ensure-CuratedSuperpowersSkills {
    $skillsDir = Join-Path $SourceDir "skills"
    Ensure-Dir $skillsDir
    Cleanup-LegacySuperpowersNamespace

    foreach ($skill in $CuratedSuperpowersSkills) {
        $sourceSkill = Join-Path (Join-Path $SuperpowersDir "skills") $skill
        if (-not (Test-Path -LiteralPath $sourceSkill -PathType Container)) {
            throw "Missing curated superpowers skill: $sourceSkill"
        }

        Ensure-DirectoryLink -Source $sourceSkill -Target (Join-Path $skillsDir $skill)
    }
}

function Ensure-CodexSkillLinks {
    $codexSkillsDir = Join-Path $TargetHome ".codex\skills"
    Ensure-Dir $codexSkillsDir
    Remove-DeprecatedCodexSkills -CodexSkillsDir $codexSkillsDir

    Get-ChildItem -LiteralPath (Join-Path $SourceDir "skills") -Force | ForEach-Object {
        Ensure-DirectoryLink -Source $_.FullName -Target (Join-Path $codexSkillsDir $_.Name)
    }
}

function Remove-DeprecatedCodexSkills {
    param([string]$CodexSkillsDir)

    foreach ($skill in $DeprecatedCodexSkills) {
        $target = Join-Path $CodexSkillsDir $skill
        if (Test-PathOrLink $target) {
            Backup-Path $target
        }
    }
}

function Ensure-CodexConfigFile {
    $sourceConfig = Join-Path (Join-Path $SourceDir ".codex") "config.toml"
    $targetConfig = Join-Path $TargetHome ".codex\config.toml"

    Ensure-Dir (Split-Path -Parent $targetConfig)
    if (-not (Test-Path -LiteralPath $sourceConfig -PathType Leaf)) {
        throw "Missing source Codex config: $sourceConfig"
    }

    $targetItem = if (Test-Path -LiteralPath $targetConfig) { Get-Item -LiteralPath $targetConfig -Force } else { $null }
    $isLink = $null -ne $targetItem -and $null -ne $targetItem.PSObject.Properties["LinkType"] -and $null -ne $targetItem.LinkType

    if ($SyncCodexConfig) {
        if ($isLink) {
            Invoke-Step "remove Codex config link $targetConfig" {
                Remove-Item -LiteralPath $targetConfig
            }
        }
        Invoke-Step "copy Codex config $sourceConfig -> $targetConfig" {
            Copy-Item -LiteralPath $sourceConfig -Destination $targetConfig -Force
        }
        Log "Copied Codex config: $sourceConfig -> $targetConfig"
        return
    }

    if ($isLink) {
        $linkedTargets = @(Get-LinkTargets $targetConfig)
        if ($linkedTargets.Count -lt 1 -or -not (Test-Path -LiteralPath $linkedTargets[0] -PathType Leaf)) {
            throw "Codex config symlink points to a missing file: $targetConfig"
        }
        if ($DryRun) {
            Write-Host "[dry-run] replace Codex config symlink with regular file copied from $($linkedTargets[0])"
            return
        }
        $tempConfig = [System.IO.Path]::GetTempFileName()
        Copy-Item -LiteralPath $linkedTargets[0] -Destination $tempConfig -Force
        Remove-Item -LiteralPath $targetConfig
        Move-Item -LiteralPath $tempConfig -Destination $targetConfig
        Log "Converted Codex config symlink to regular file: $targetConfig"
        return
    }

    if (Test-Path -LiteralPath $targetConfig) {
        Log "Keeping existing Codex config file: $targetConfig"
    } else {
        Log "Codex config file missing; pass -SyncCodexConfig to create it from $sourceConfig"
    }
}

Log "Source directory: $SourceDir"
Log "Superpowers directory: $SuperpowersDir"
Log "Superpowers remote: $SuperpowersRemoteUrl"
Log "Superpowers branch: $SuperpowersBranch"
Log "Humanize sync: $HumanizeSync"
if ($HumanizeSync -ne "0") {
    Log "Humanize directory: $HumanizeDir"
    Log "Humanize remote: $HumanizeRemoteUrl"
    Log "Humanize branch: $HumanizeBranch"
}
Log "Backup directory: $BackupRoot"
Log "Kimi Code home: $KimiCodeHome"

Ensure-SuperpowersRepo
Ensure-HumanizeRepo
Repair-HumanizeCodexHookProbe
Repair-HumanizeCodexHooksFeatureName
Ensure-CuratedSuperpowersSkills

Ensure-FileSymlink -Source (Join-Path $SourceDir "CLAUDE.md") -Target (Join-Path $TargetHome ".claude\CLAUDE.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".claude\skills")
Ensure-FileSymlink -Source (Join-Path $SourceDir "settings.json") -Target (Join-Path $TargetHome ".claude\settings.json")

Ensure-FileSymlink -Source (Join-Path $SourceDir "CLAUDE.md") -Target (Join-Path $TargetHome ".gemini\GEMINI.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".gemini\skills")

Ensure-FileSymlink -Source (Join-Path $SourceDir "CLAUDE.md") -Target (Join-Path $TargetHome ".copilot\copilot-instructions.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".copilot\skills")
Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $TargetHome ".copilot\AGENTS.md")

Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $TargetHome ".codex\AGENTS.md")
Ensure-CodexConfigFile
Ensure-DirectoryLink -Source (Join-Path $SourceDir ".codex\agents") -Target (Join-Path $TargetHome ".codex\agents")
Install-HumanizeRlcr
Ensure-CodexSkillLinks

Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $KimiCodeHome "AGENTS.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $KimiCodeHome "skills")
Install-KimiStopHookWrapper
Ensure-KimiStopHookConfig

Log "Sync complete."
