param(
    [switch]$DryRun
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
$BackupRoot = Join-Path $TargetHome (".coding-cli-sync-backups\" + (Get-Date -Format "yyyyMMdd_HHmmss"))
$CuratedSuperpowersSkills = @(
    "using-superpowers",
    "brainstorming",
    "writing-plans",
    "executing-plans",
    "test-driven-development",
    "verification-before-completion"
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

function Backup-Path {
    param([string]$Target)

    if (Test-Path -LiteralPath $Target) {
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

function Install-HumanizeCodexRlcr {
    if ($HumanizeSync -eq "0") {
        return
    }

    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        throw "bash is required to run Humanize's Codex installer. Install bash or set HUMANIZE_SYNC=0."
    }

    $installer = Join-Path (Join-Path $HumanizeDir "scripts") "install-skill.sh"
    $oldHome = $env:HOME
    $oldCodexHome = $env:CODEX_HOME
    try {
        $env:HOME = $TargetHome
        $env:CODEX_HOME = Join-Path $TargetHome ".codex"
        Invoke-NativeChecked "Humanize Codex RLCR install" {
            bash $installer --target codex
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

    Get-ChildItem -LiteralPath (Join-Path $SourceDir "skills") -Force | ForEach-Object {
        Ensure-DirectoryLink -Source $_.FullName -Target (Join-Path $codexSkillsDir $_.Name)
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

Ensure-SuperpowersRepo
Ensure-HumanizeRepo
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
Ensure-FileSymlink -Source (Join-Path $SourceDir ".codex\config.toml") -Target (Join-Path $TargetHome ".codex\config.toml")
Ensure-DirectoryLink -Source (Join-Path $SourceDir ".codex\agents") -Target (Join-Path $TargetHome ".codex\agents")
Ensure-CodexSkillLinks
Install-HumanizeCodexRlcr

Log "Sync complete."
