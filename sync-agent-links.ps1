param(
    [switch]$DryRun,
    [switch]$UpdateSuperpowers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetHome = if ($env:SYNC_HOME) { $env:SYNC_HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { throw "USERPROFILE is not set." }
$SuperpowersDir = if ($env:SUPERPOWERS_DIR) { $env:SUPERPOWERS_DIR } else { Join-Path $SourceDir "superpowers" }
$SuperpowersRemoteUrl = if ($env:SUPERPOWERS_REMOTE_URL) { $env:SUPERPOWERS_REMOTE_URL } else { "https://github.com/obra/superpowers.git" }
$SuperpowersSkillsLink = if ($env:SUPERPOWERS_SKILLS_LINK) { $env:SUPERPOWERS_SKILLS_LINK } else { Join-Path (Join-Path $SourceDir "skills") "superpowers" }
$BackupRoot = Join-Path $TargetHome (".coding-cli-sync-backups\" + (Get-Date -Format "yyyyMMdd_HHmmss"))

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

function Backup-Path {
    param([string]$Target)

    if (Test-Path -LiteralPath $Target) {
        Ensure-Dir $BackupRoot
        $relative = $Target.TrimStart('\').TrimStart('/')
        $backupTarget = Join-Path $BackupRoot $relative
        Ensure-Dir (Split-Path -Parent $backupTarget)
        Invoke-Step "move $Target -> $backupTarget" { Move-Item -LiteralPath $Target -Destination $backupTarget }
        Log "Backed up $Target -> $backupTarget"
    }
}

function Get-LinkTarget {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $item = Get-Item -LiteralPath $Path -Force
    $linkTargetProperty = $item.PSObject.Properties["LinkTarget"]
    if ($null -ne $linkTargetProperty) {
        $linkTarget = $linkTargetProperty.Value
        if ($linkTarget -is [System.Array]) {
            return [string]$linkTarget[0]
        }
        return [string]$linkTarget
    }

    $targetProperty = $item.PSObject.Properties["Target"]
    if ($null -ne $targetProperty) {
        $target = $targetProperty.Value
        if ($target -is [System.Array]) {
            return [string]$target[0]
        }
        if ($null -ne $target) {
            return [string]$target
        }
    }

    return $null
}

function Ensure-FileSymlink {
    param(
        [string]$Source,
        [string]$Target
    )

    Ensure-Dir (Split-Path -Parent $Target)

    $current = Get-LinkTarget $Target
    if ($current -eq $Source) {
        Log "OK symlink: $Target -> $Source"
        return
    }

    if (Test-Path -LiteralPath $Target) {
        Backup-Path $Target
    }

    Invoke-Step "symlink $Target -> $Source" {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    }
    Log "Linked $Target -> $Source"
}

function Ensure-DirectoryLink {
    param(
        [string]$Source,
        [string]$Target
    )

    Ensure-Dir (Split-Path -Parent $Target)

    $current = Get-LinkTarget $Target
    if ($current -eq $Source) {
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

function Require-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git is required for superpowers clone/update"
    }
}

function Ensure-SuperpowersRepo {
    if (-not (Test-Path -LiteralPath $SuperpowersDir)) {
        Require-Git
        Ensure-Dir (Split-Path -Parent $SuperpowersDir)
        Invoke-Step "git clone $SuperpowersRemoteUrl $SuperpowersDir" {
            git clone $SuperpowersRemoteUrl $SuperpowersDir | Out-Null
        }
        Log "Cloned superpowers into $SuperpowersDir"
        return
    }

    if ((Test-Path -LiteralPath $SuperpowersDir -PathType Container) -and -not (Get-ChildItem -LiteralPath $SuperpowersDir -Force | Select-Object -First 1)) {
        Require-Git
        Invoke-Step "git clone $SuperpowersRemoteUrl $SuperpowersDir" {
            git clone $SuperpowersRemoteUrl $SuperpowersDir | Out-Null
        }
        Log "Cloned superpowers into empty directory $SuperpowersDir"
        return
    }

    if (-not (Test-Path -LiteralPath (Join-Path $SuperpowersDir ".git"))) {
        throw "Existing superpowers path is not a git repository: $SuperpowersDir"
    }
}

function Update-SuperpowersRepo {
    if (-not $UpdateSuperpowers) {
        return
    }

    Require-Git

    $status = git -C $SuperpowersDir status --porcelain
    if ($status) {
        throw "Superpowers checkout has uncommitted changes: $SuperpowersDir"
    }

    $headOk = $true
    try {
        git -C $SuperpowersDir symbolic-ref --quiet HEAD | Out-Null
    } catch {
        $headOk = $false
    }
    if (-not $headOk) {
        throw "Superpowers checkout is in detached HEAD state: $SuperpowersDir"
    }

    $upstream = $null
    try {
        $upstream = (git -C $SuperpowersDir rev-parse --abbrev-ref --symbolic-full-name "@{upstream}").Trim()
    } catch {
        throw "Superpowers checkout has no configured upstream branch: $SuperpowersDir"
    }

    Invoke-Step "git fetch --prune" {
        git -C $SuperpowersDir fetch --prune | Out-Null
    }
    Invoke-Step "git merge --ff-only $upstream" {
        git -C $SuperpowersDir merge --ff-only $upstream | Out-Null
    }
    Log "Updated superpowers from $upstream"
}

function Ensure-SuperpowersSkillsLink {
    Ensure-DirectoryLink -Source (Join-Path $SuperpowersDir "skills") -Target $SuperpowersSkillsLink
}

function Cleanup-CodexSkillOverrides {
    $codexSkillsDir = Join-Path $TargetHome ".codex\skills"
    if (-not (Test-Path -LiteralPath $codexSkillsDir -PathType Container)) {
        return
    }

    Get-ChildItem -LiteralPath $codexSkillsDir -Force | ForEach-Object {
        $name = $_.Name
        if ($name -in @(".system", "skills")) {
            return
        }

        $sourceSkill = Join-Path (Join-Path $SourceDir "skills") $name
        if (Test-Path -LiteralPath $sourceSkill -PathType Container) {
            Backup-Path $_.FullName
        }
    }
}

Log "Source directory: $SourceDir"
Log "Superpowers directory: $SuperpowersDir"
Log "Backup directory: $BackupRoot"

Ensure-SuperpowersRepo
Update-SuperpowersRepo
Ensure-SuperpowersSkillsLink

Ensure-FileSymlink -Source (Join-Path $SourceDir "CLAUDE.md") -Target (Join-Path $TargetHome ".claude\CLAUDE.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".claude\skills")
Ensure-FileSymlink -Source (Join-Path $SourceDir "settings.json") -Target (Join-Path $TargetHome ".claude\settings.json")

Ensure-FileSymlink -Source (Join-Path $SourceDir "CLAUDE.md") -Target (Join-Path $TargetHome ".gemini\GEMINI.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".gemini\skills")

Ensure-FileSymlink -Source (Join-Path $SourceDir "CLAUDE.md") -Target (Join-Path $TargetHome ".copilot\copilot-instructions.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".copilot\skills")
Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $TargetHome ".copilot\AGENTS.md")

Cleanup-CodexSkillOverrides
Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $TargetHome ".codex\AGENTS.md")
Ensure-FileSymlink -Source (Join-Path $SourceDir ".codex\config.toml") -Target (Join-Path $TargetHome ".codex\config.toml")
Ensure-DirectoryLink -Source (Join-Path $SourceDir ".codex\agents") -Target (Join-Path $TargetHome ".codex\agents")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".codex\skills\skills")

Log "Sync complete."
