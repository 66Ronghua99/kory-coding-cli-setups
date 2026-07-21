param(
    [switch]$DryRun,
    [switch]$SyncCodexConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetHome = if ($env:SYNC_HOME) { $env:SYNC_HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { throw "USERPROFILE is not set." }
$KimiCodeHome = if ($env:KIMI_CODE_HOME) { $env:KIMI_CODE_HOME } else { Join-Path $TargetHome ".kimi-code" }
$OmpAgentHome = if ($env:PI_CODING_AGENT_DIR) { $env:PI_CODING_AGENT_DIR } else { Join-Path $TargetHome ".omp\agent" }
$BackupRoot = Join-Path $TargetHome (".coding-cli-sync-backups\" + (Get-Date -Format "yyyyMMdd_HHmmss"))
$RequiredLocalSkills = @("brainstorming", "writing-plans", "executing-plans")
$RetiredSkills = @(
    "using-superpowers",
    "test-driven-development",
    "verification-before-completion",
    "superman",
    "code-simplifier",
    "harness-doc-health",
    "content-creator-collab",
    "humanize",
    "humanize-gen-plan",
    "humanize-refine-plan",
    "humanize-rlcr"
)
$LegacyCodexSkills = @("harness-lint-test-design", "harness-refactor")

function Log {
    param([string]$Message)
    Write-Host $Message
}

function Invoke-Step {
    param([string]$Label, [scriptblock]$Action)
    if ($DryRun) {
        Write-Host "[dry-run] $Label"
        return
    }
    & $Action
}

function Invoke-NativeChecked {
    param([string]$Label, [scriptblock]$Action)
    Invoke-Step $Label {
        & $Action
        if ($LASTEXITCODE -ne 0) {
            throw "$Label failed with exit code $LASTEXITCODE"
        }
    }
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Invoke-Step "mkdir $Path" { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
    }
}

function Normalize-ComparablePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    try { $fullPath = [System.IO.Path]::GetFullPath($Path) } catch { $fullPath = [string]$Path }
    return $fullPath.TrimEnd('\', '/').ToLowerInvariant()
}

function Get-BackupRelativePath {
    param([string]$Path)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($root)) { return $fullPath.TrimStart('\', '/') }
    $rootLabel = ($root -replace '[:\\\/]+', '').Trim()
    if ([string]::IsNullOrWhiteSpace($rootLabel)) { $rootLabel = "root" }
    $relative = $fullPath.Substring($root.Length).TrimStart('\', '/')
    if ([string]::IsNullOrWhiteSpace($relative)) { return $rootLabel }
    return Join-Path $rootLabel $relative
}

function Test-SameVolume {
    param([string]$LeftPath, [string]$RightPath)
    $leftRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($LeftPath))
    $rightRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($RightPath))
    return [string]::Equals($leftRoot, $rightRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-PathOrLink {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) { return $true }
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
        $backupTarget = Join-Path $BackupRoot (Get-BackupRelativePath $Target)
        Ensure-Dir (Split-Path -Parent $backupTarget)
        Invoke-Step "move $Target -> $backupTarget" { Move-Item -LiteralPath $Target -Destination $backupTarget }
        Log "Backed up $Target -> $backupTarget"
    }
}

function Get-LinkTargets {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $item = Get-Item -LiteralPath $Path -Force
    foreach ($propertyName in @("LinkTarget", "Target")) {
        $property = $item.PSObject.Properties[$propertyName]
        if ($null -ne $property -and $null -ne $property.Value) {
            if ($property.Value -is [System.Array]) { return @($property.Value | ForEach-Object { [string]$_ }) }
            return @([string]$property.Value)
        }
    }
    return @()
}

function Ensure-FileSymlink {
    param([string]$Source, [string]$Target)
    Ensure-Dir (Split-Path -Parent $Target)
    $normalizedSource = Normalize-ComparablePath $Source
    $currentTargets = @(Get-LinkTargets $Target | ForEach-Object { Normalize-ComparablePath $_ })
    if ($currentTargets -contains $normalizedSource) {
        Log "OK file link: $Target -> $Source"
        return
    }
    if ((Test-Path -LiteralPath $Source -PathType Leaf) -and (Test-Path -LiteralPath $Target -PathType Leaf)) {
        if ((Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Target).Hash) {
            Log "OK file sync: $Target matches $Source"
            return
        }
    }
    if (Test-PathOrLink $Target) { Backup-Path $Target }
    try {
        Invoke-Step "file symlink $Target -> $Source" { New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null }
    } catch {
        if (-not (Test-SameVolume -LeftPath $Source -RightPath $Target)) { throw }
        Invoke-Step "hardlink $Target -> $Source" { New-Item -ItemType HardLink -Path $Target -Target $Source | Out-Null }
    }
    Log "Linked $Target -> $Source"
}

function Ensure-DirectoryLink {
    param([string]$Source, [string]$Target)
    Ensure-Dir (Split-Path -Parent $Target)
    $normalizedSource = Normalize-ComparablePath $Source
    $currentTargets = @(Get-LinkTargets $Target | ForEach-Object { Normalize-ComparablePath $_ })
    if ($currentTargets -contains $normalizedSource) {
        Log "OK directory link: $Target -> $Source"
        return
    }
    if (Test-PathOrLink $Target) { Backup-Path $Target }
    try {
        Invoke-Step "directory symlink $Target -> $Source" { New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null }
    } catch {
        Invoke-Step "junction $Target -> $Source" { cmd /c "mklink /J `"$Target`" `"$Source`"" | Out-Null }
    }
    Log "Linked $Target -> $Source"
}

function Assert-LocalSkills {
    foreach ($skill in $RequiredLocalSkills) {
        $skillDir = Join-Path $SourceDir "skills\$skill"
        if (-not (Test-Path -LiteralPath $skillDir -PathType Container)) {
            throw "Missing local skill directory: $skillDir"
        }

        $skillItem = Get-Item -LiteralPath $skillDir -Force
        if ($null -ne $skillItem.PSObject.Properties["LinkType"] -and $null -ne $skillItem.LinkType) {
            throw "Local skill must be a real directory: $skillDir"
        }

        $skillFile = Join-Path $skillDir "SKILL.md"
        if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
            throw "Missing local skill file: $skillFile"
        }

        $match = [regex]::Match((Get-Content -LiteralPath $skillFile -Raw), '(?m)^name:\s*([^\r\n]+)\s*$')
        $declaredName = if ($match.Success) { $match.Groups[1].Value.Trim() } else { "" }
        if ($declaredName -ne $skill) {
            throw "Invalid local skill name in ${skillFile}: expected $skill, found $(if ($declaredName) { $declaredName } else { '<missing>' })"
        }
    }
    Log "Validated local skills: $($RequiredLocalSkills -join ', ')"
}

function Remove-CodexHumanizeHooks {
    $hooksFile = Join-Path $TargetHome ".codex\hooks.json"
    if (-not (Test-Path -LiteralPath $hooksFile -PathType Leaf)) { return }
    if ($DryRun) {
        Log "[dry-run] remove managed Humanize hooks from $hooksFile"
        return
    }

    $data = Get-Content -LiteralPath $hooksFile -Raw | ConvertFrom-Json
    if ($null -eq $data -or $null -eq $data.hooks -or $null -eq $data.hooks.Stop) { return }
    $changed = $false
    $keptGroups = @()
    foreach ($group in @($data.hooks.Stop)) {
        if ($null -eq $group.hooks) {
            $keptGroups += $group
            continue
        }
        $keptCommands = @()
        foreach ($hook in @($group.hooks)) {
            $managed = $hook.type -eq "command" -and [string]$hook.command -like "*/skills/humanize/*"
            if ($managed) { $changed = $true } else { $keptCommands += $hook }
        }
        if ($keptCommands.Count -gt 0) {
            $group.hooks = @($keptCommands)
            $keptGroups += $group
        } elseif (@($group.hooks).Count -gt 0) {
            $changed = $true
        }
    }
    if (-not $changed) { return }
    if ($keptGroups.Count -gt 0) {
        $data.hooks.Stop = @($keptGroups)
    } else {
        $data.hooks.PSObject.Properties.Remove("Stop")
    }
    if ($data.hooks.PSObject.Properties.Count -eq 0) { $data.PSObject.Properties.Remove("hooks") }
    ($data | ConvertTo-Json -Depth 20) + "`n" | Set-Content -LiteralPath $hooksFile -NoNewline
    Log "Removed managed Humanize hooks from $hooksFile"
}

function Remove-KimiHumanizeHooks {
    $configFile = Join-Path $KimiCodeHome "config.toml"
    if (-not (Test-Path -LiteralPath $configFile -PathType Leaf)) { return }
    if ($DryRun) {
        Log "[dry-run] remove managed Humanize hooks from $configFile"
        return
    }

    $content = Get-Content -LiteralPath $configFile -Raw
    $pattern = '(?ms)^\[\[hooks\]\]\r?\n(?:(?!^\[).*(?:\r?\n|\z))*'
    $updated = [regex]::Replace(
        $content,
        $pattern,
        [System.Text.RegularExpressions.MatchEvaluator]{
            param($match)
            $block = $match.Value
            $managed = $block -match '(?m)^event\s*=\s*["'']Stop["'']\s*$' -and $block -match '(?m)^command\s*=\s*["''][^"'']*/skills/humanize/[^"'']*["'']\s*$'
            if ($managed) { return "" }
            return $block
        }
    )
    if ($updated -ne $content) {
        Set-Content -LiteralPath $configFile -Value $updated -NoNewline
        Log "Removed managed Humanize hooks from $configFile"
    }
}

function Remove-RetiredAssets {
    Backup-Path (Join-Path $SourceDir "humanize")
    Backup-Path (Join-Path $SourceDir "skills\superpowers")
    foreach ($skill in $RetiredSkills) {
        Backup-Path (Join-Path $SourceDir "skills\$skill")
        Backup-Path (Join-Path $TargetHome ".codex\skills\$skill")
    }
    foreach ($skill in $LegacyCodexSkills) {
        Backup-Path (Join-Path $TargetHome ".codex\skills\$skill")
    }
    Remove-CodexHumanizeHooks
    Remove-KimiHumanizeHooks
}


function Ensure-CodexSkillLinks {
    $codexSkillsDir = Join-Path $TargetHome ".codex\skills"
    Ensure-Dir $codexSkillsDir
    foreach ($item in Get-ChildItem -LiteralPath (Join-Path $SourceDir "skills") -Force) {
        if ($RetiredSkills -contains $item.Name) { continue }
        Ensure-DirectoryLink -Source $item.FullName -Target (Join-Path $codexSkillsDir $item.Name)
    }
}

function Ensure-CodexConfigFile {
    $sourceConfig = Join-Path $SourceDir ".codex\config.toml"
    $targetConfig = Join-Path $TargetHome ".codex\config.toml"
    Ensure-Dir (Split-Path -Parent $targetConfig)
    if (-not (Test-Path -LiteralPath $sourceConfig -PathType Leaf)) { throw "Missing source Codex config: $sourceConfig" }
    $targetItem = if (Test-Path -LiteralPath $targetConfig) { Get-Item -LiteralPath $targetConfig -Force } else { $null }
    $isLink = $null -ne $targetItem -and $null -ne $targetItem.PSObject.Properties["LinkType"] -and $null -ne $targetItem.LinkType

    if ($SyncCodexConfig) {
        if ($isLink) { Invoke-Step "remove Codex config link $targetConfig" { Remove-Item -LiteralPath $targetConfig } }
        Invoke-Step "copy Codex config $sourceConfig -> $targetConfig" { Copy-Item -LiteralPath $sourceConfig -Destination $targetConfig -Force }
        Log "Copied Codex config: $sourceConfig -> $targetConfig"
        return
    }
    if ($isLink) {
        $linkedTargets = @(Get-LinkTargets $targetConfig)
        if ($linkedTargets.Count -lt 1 -or -not (Test-Path -LiteralPath $linkedTargets[0] -PathType Leaf)) { throw "Codex config symlink points to a missing file: $targetConfig" }
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
    if (Test-Path -LiteralPath $targetConfig) { Log "Keeping existing Codex config file: $targetConfig" } else { Log "Codex config file missing; pass -SyncCodexConfig to create it from $sourceConfig" }
}

Log "Source directory: $SourceDir"
Log "Backup directory: $BackupRoot"
Log "Kimi Code home: $KimiCodeHome"
Log "OMP agent home: $OmpAgentHome"

Assert-LocalSkills
Remove-RetiredAssets

Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $TargetHome ".claude\CLAUDE.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".claude\skills")
Ensure-FileSymlink -Source (Join-Path $SourceDir "settings.json") -Target (Join-Path $TargetHome ".claude\settings.json")
Ensure-FileSymlink -Source (Join-Path $SourceDir "statusline-command.sh") -Target (Join-Path $TargetHome ".claude\statusline-command.sh")

Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $TargetHome ".gemini\GEMINI.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".gemini\skills")

Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $TargetHome ".copilot\copilot-instructions.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $TargetHome ".copilot\skills")
Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $TargetHome ".copilot\AGENTS.md")

Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $TargetHome ".codex\AGENTS.md")
Ensure-CodexConfigFile
Ensure-DirectoryLink -Source (Join-Path $SourceDir ".codex\agents") -Target (Join-Path $TargetHome ".codex\agents")
Ensure-CodexSkillLinks

Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $KimiCodeHome "AGENTS.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $KimiCodeHome "skills")

Ensure-FileSymlink -Source (Join-Path $SourceDir "AGENTS.md") -Target (Join-Path $OmpAgentHome "AGENTS.md")
Ensure-DirectoryLink -Source (Join-Path $SourceDir "skills") -Target (Join-Path $OmpAgentHome "skills")

Log "Sync complete."
