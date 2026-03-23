param(
    [switch]$DryRun,
    [switch]$UpdateSuperpowers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetHome = if ($env:SYNC_HOME) { $env:SYNC_HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { throw "USERPROFILE is not set." }
$SuperpowersDir = if ($env:SUPERPOWERS_DIR) { $env:SUPERPOWERS_DIR } else { Join-Path $SourceDir "superpowers" }
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
    if (-not (Test-Path -LiteralPath $SuperpowersDir)) {
        throw "Missing superpowers checkout: $SuperpowersDir. Run 'git submodule update --init --recursive'."
    }

    if (-not (Test-Path -LiteralPath (Join-Path $SuperpowersDir ".git"))) {
        throw "Existing superpowers path is not a git repository: $SuperpowersDir"
    }

    if (-not (Test-Path -LiteralPath (Join-Path $SuperpowersDir "skills") -PathType Container)) {
        throw "Missing superpowers skills directory: $SuperpowersDir\skills. Run 'git submodule update --init --recursive'."
    }
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

if ($UpdateSuperpowers) {
    throw "--UpdateSuperpowers is no longer supported. Run 'git submodule update --remote superpowers' manually first."
}

Ensure-SuperpowersRepo
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
