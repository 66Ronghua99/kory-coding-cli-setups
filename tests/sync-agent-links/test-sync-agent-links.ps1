param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CuratedSkills = @("brainstorming", "writing-plans", "executing-plans")
$LocalSkillDirs = @("harness-init", "frontend-slides-2.0.0", "grill-with-docs")
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

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Exists {
    param([string]$Path)
    Assert-True (Test-Path -LiteralPath $Path) "Expected path to exist: $Path"
}

function Assert-NotExists {
    param([string]$Path)
    Assert-True (-not (Test-Path -LiteralPath $Path)) "Expected path to be absent: $Path"
}

function Assert-RealDirectory {
    param([string]$Path)
    Assert-Exists $Path
    $item = Get-Item -LiteralPath $Path -Force
    $isLink = $null -ne $item.PSObject.Properties["LinkType"] -and $null -ne $item.LinkType
    Assert-True (-not $isLink -and $item.PSIsContainer) "Expected real directory: $Path"
}

function Assert-FileContains {
    param([string]$Path, [string]$Expected)
    $content = Get-Content -LiteralPath $Path -Raw
    Assert-True $content.Contains($Expected) "Expected $Path to contain: $Expected"
}

function Assert-FileNotContains {
    param([string]$Path, [string]$Unexpected)
    $content = Get-Content -LiteralPath $Path -Raw
    Assert-True (-not $content.Contains($Unexpected)) "Expected $Path not to contain: $Unexpected"
}

function Assert-FileReflectsSource {
    param([string]$Source, [string]$Target)
    Assert-Exists $Target
    Assert-True ((Get-Content -LiteralPath $Source -Raw) -eq (Get-Content -LiteralPath $Target -Raw)) "Expected $Target to reflect $Source"
}


function New-FakeSource {
    param([string]$SourceDir, [string]$RepoRoot)

    New-Item -ItemType Directory -Force -Path (Join-Path $SourceDir ".codex\agents") | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot "sync-agent-links.ps1") -Destination (Join-Path $SourceDir "sync-agent-links.ps1")
    "# AGENTS" | Set-Content -LiteralPath (Join-Path $SourceDir "AGENTS.md")
    '{}' | Set-Content -LiteralPath (Join-Path $SourceDir "settings.json")
    'printf "statusline\n"' | Set-Content -LiteralPath (Join-Path $SourceDir "statusline-command.sh")
    'model = "gpt-test"' | Set-Content -LiteralPath (Join-Path $SourceDir ".codex\config.toml")
    'description = "explorer"' | Set-Content -LiteralPath (Join-Path $SourceDir ".codex\agents\explorer.toml")

    New-Item -ItemType Directory -Force -Path (Join-Path $SourceDir "skills") | Out-Null
    foreach ($skill in $CuratedSkills) {
        Copy-Item -LiteralPath (Join-Path $RepoRoot "skills\$skill") -Destination (Join-Path $SourceDir "skills\$skill") -Recurse
    }

    foreach ($skillDirName in $LocalSkillDirs) {
        $skillName = switch ($skillDirName) {
            "harness-init" { "harness:init" }
            "frontend-slides-2.0.0" { "frontend-slides" }
            "grill-with-docs" { "grill-with-docs" }
        }
        $skillDir = Join-Path $SourceDir "skills\$skillDirName"
        New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
        @"
---
name: $skillName
description: local fixture
---
"@ | Set-Content -LiteralPath (Join-Path $skillDir "SKILL.md")
    }
}

function Invoke-Sync {
    param([string]$SourceDir, [string]$HomeDir, [string]$OmpHome = "")

    $env:SYNC_HOME = $HomeDir
    $env:PI_CODING_AGENT_DIR = if ($OmpHome) { $OmpHome } else { Join-Path $HomeDir ".omp\agent" }
    try {
        & (Join-Path $SourceDir "sync-agent-links.ps1")
    } finally {
        Remove-Item Env:SYNC_HOME -ErrorAction SilentlyContinue
        Remove-Item Env:PI_CODING_AGENT_DIR -ErrorAction SilentlyContinue
    }
}

function Seed-RetiredAssets {
    param([string]$SourceDir, [string]$HomeDir)

    New-Item -ItemType Directory -Force -Path (Join-Path $SourceDir "humanize\.git") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $HomeDir ".codex\skills") | Out-Null
    foreach ($skill in $RetiredSkills) {
        New-Item -ItemType Directory -Force -Path (Join-Path $SourceDir "skills\$skill") | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $HomeDir ".codex\skills\$skill") | Out-Null
        "legacy" | Set-Content -LiteralPath (Join-Path $SourceDir "skills\$skill\SKILL.md")
        "legacy" | Set-Content -LiteralPath (Join-Path $HomeDir ".codex\skills\$skill\SKILL.md")
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $HomeDir ".codex") | Out-Null
    @"
{
  "hooks": {
    "Stop": [{"hooks": [
      {"type": "command", "command": "$SourceDir/skills/humanize/hooks/loop-codex-stop-hook.sh"},
      {"type": "command", "command": "/keep/unknown-stop-hook.sh"}
    ]}],
    "Notification": [{"hooks": [{"type": "command", "command": "/keep/notification.sh"}]}]
  }
}
"@ | Set-Content -LiteralPath (Join-Path $HomeDir ".codex\hooks.json")
    New-Item -ItemType Directory -Force -Path (Join-Path $HomeDir ".kimi-code") | Out-Null
    @"
[[hooks]]
event = "Stop"
command = "$SourceDir/skills/humanize/hooks/loop-kimi-stop-hook.sh"
timeout = 600

[[hooks]]
event = "Stop"
command = "/keep/unknown-kimi-hook.sh"
timeout = 30

[loop_control]
max_retries_per_step = 3
"@ | Set-Content -LiteralPath (Join-Path $HomeDir ".kimi-code\config.toml")
}

function Test-SyncContract {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    $env:SUPERPOWERS_REMOTE_URL = Join-Path $tempdir "does-not-exist.git"
    try {
        Invoke-Sync -SourceDir $source -HomeDir $homeDir
    } finally {
        Remove-Item Env:SUPERPOWERS_REMOTE_URL -ErrorAction SilentlyContinue
    }

    foreach ($skill in $CuratedSkills) {
        Assert-RealDirectory (Join-Path $source "skills\$skill")
        Assert-Exists (Join-Path $source "skills\$skill\SKILL.md")
        Assert-Exists (Join-Path $homeDir ".codex\skills\$skill\SKILL.md")
    }
    Assert-Exists (Join-Path $homeDir ".codex\skills\executing-plans\scripts\run-codex-review.sh")
    Assert-Exists (Join-Path $homeDir ".codex\skills\executing-plans\scripts\run-codex-review.ps1")
    foreach ($skillDir in $LocalSkillDirs) {
        Assert-Exists (Join-Path $homeDir ".codex\skills\$skillDir\SKILL.md")
    }
    Assert-NotExists (Join-Path $source "superpowers")
    Assert-FileReflectsSource -Source (Join-Path $source "AGENTS.md") -Target (Join-Path $homeDir ".claude\CLAUDE.md")
    Assert-FileReflectsSource -Source (Join-Path $source "statusline-command.sh") -Target (Join-Path $homeDir ".claude\statusline-command.sh")
    Assert-FileReflectsSource -Source (Join-Path $source "AGENTS.md") -Target (Join-Path $homeDir ".gemini\GEMINI.md")
    Assert-FileReflectsSource -Source (Join-Path $source "AGENTS.md") -Target (Join-Path $homeDir ".copilot\copilot-instructions.md")
    Assert-FileReflectsSource -Source (Join-Path $source "AGENTS.md") -Target (Join-Path $homeDir ".codex\AGENTS.md")
    Assert-FileReflectsSource -Source (Join-Path $source "AGENTS.md") -Target (Join-Path $homeDir ".kimi-code\AGENTS.md")
    Assert-FileReflectsSource -Source (Join-Path $source "AGENTS.md") -Target (Join-Path $homeDir ".omp\agent\AGENTS.md")
    Assert-Exists (Join-Path $homeDir ".omp\agent\skills\brainstorming\SKILL.md")
    Assert-Exists (Join-Path $homeDir ".omp\agent\skills\executing-plans\SKILL.md")

    $brainstorming = Join-Path $source "skills\brainstorming\SKILL.md"
    $writingPlans = Join-Path $source "skills\writing-plans\SKILL.md"
    $executingPlans = Join-Path $source "skills\executing-plans\SKILL.md"
    Assert-FileContains -Path $brainstorming -Expected "without staging or committing it"
    Assert-FileContains -Path $writingPlans -Expected "Do not stage or commit"
    Assert-FileContains -Path $executingPlans -Expected "name: executing-plans"
    Assert-FileContains -Path $executingPlans -Expected "Never install or depend on hooks"
    foreach ($forbidden in @(
        "superpowers:using-git-worktrees",
        "superpowers:subagent-driven-development",
        "superpowers:executing-plans",
        "elements-of-style:",
        "Commit the design document to git",
        "git add ",
        "git commit ",
        "https://github.com/obra/superpowers",
        "https://primeradiant.com"
    )) {
        Assert-FileNotContains -Path $brainstorming -Unexpected $forbidden
        Assert-FileNotContains -Path $writingPlans -Unexpected $forbidden
    }
    $server = Join-Path $source "skills\brainstorming\scripts\server.cjs"
    Assert-FileNotContains -Path $server -Unexpected "https://github.com/obra/superpowers"
    Assert-FileNotContains -Path $server -Unexpected "https://primeradiant.com"
    Assert-FileNotContains -Path $server -Unexpected "SUPERPOWERS_VERSION"
}

function Test-MissingLocalSkillFailsBeforeMutation {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    Remove-Item -LiteralPath (Join-Path $source "skills\brainstorming") -Recurse
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    $failed = $false
    try {
        Invoke-Sync -SourceDir $source -HomeDir $homeDir
    } catch {
        $failed = $true
        Assert-True ($_.Exception.Message.Contains("Missing local skill directory")) "Unexpected failure: $($_.Exception.Message)"
    }
    Assert-True $failed "Expected missing local skill to fail"
    Assert-NotExists (Join-Path $homeDir ".claude")
}

function Test-InvalidLocalSkillNameFailsBeforeMutation {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    "---`nname: wrong-name`n---" | Set-Content -LiteralPath (Join-Path $source "skills\brainstorming\SKILL.md")
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    $failed = $false
    try {
        Invoke-Sync -SourceDir $source -HomeDir $homeDir
    } catch {
        $failed = $true
        Assert-True ($_.Exception.Message.Contains("Invalid local skill name")) "Unexpected failure: $($_.Exception.Message)"
    }
    Assert-True $failed "Expected invalid local skill name to fail"
    Assert-NotExists (Join-Path $homeDir ".claude")
}

function Test-RetiredCleanupPreservesUnknownHooks {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null
    Seed-RetiredAssets -SourceDir $source -HomeDir $homeDir

    Invoke-Sync -SourceDir $source -HomeDir $homeDir

    Assert-NotExists (Join-Path $source "humanize")
    foreach ($skill in $RetiredSkills) {
        Assert-NotExists (Join-Path $source "skills\$skill")
        Assert-NotExists (Join-Path $homeDir ".codex\skills\$skill")
    }
    Assert-FileNotContains -Path (Join-Path $homeDir ".codex\hooks.json") -Unexpected "/skills/humanize/"
    Assert-FileContains -Path (Join-Path $homeDir ".codex\hooks.json") -Expected "/keep/unknown-stop-hook.sh"
    Assert-FileContains -Path (Join-Path $homeDir ".codex\hooks.json") -Expected "/keep/notification.sh"
    Assert-FileNotContains -Path (Join-Path $homeDir ".kimi-code\config.toml") -Unexpected "/skills/humanize/"
    Assert-FileContains -Path (Join-Path $homeDir ".kimi-code\config.toml") -Expected "/keep/unknown-kimi-hook.sh"
    Assert-FileContains -Path (Join-Path $homeDir ".kimi-code\config.toml") -Expected "max_retries_per_step = 3"
}

function Test-OmpHomeOverrideAndIdempotency {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $ompHome = Join-Path $tempdir "omp-agent"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $homeDir -OmpHome $ompHome
    Invoke-Sync -SourceDir $source -HomeDir $homeDir -OmpHome $ompHome

    Assert-FileReflectsSource -Source (Join-Path $source "AGENTS.md") -Target (Join-Path $ompHome "AGENTS.md")
    Assert-Exists (Join-Path $ompHome "skills\writing-plans\SKILL.md")
    Assert-NotExists (Join-Path $homeDir ".coding-cli-sync-backups")
}

function Test-CodexConfigIsPreserved {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path (Join-Path $homeDir ".codex") | Out-Null
    "local-config" | Set-Content -LiteralPath (Join-Path $homeDir ".codex\config.toml")

    Invoke-Sync -SourceDir $source -HomeDir $homeDir

    Assert-FileContains -Path (Join-Path $homeDir ".codex\config.toml") -Expected "local-config"
    Assert-FileNotContains -Path (Join-Path $homeDir ".codex\config.toml") -Unexpected "gpt-test"
}

Test-MissingLocalSkillFailsBeforeMutation
Test-InvalidLocalSkillNameFailsBeforeMutation
Test-SyncContract
Test-RetiredCleanupPreservesUnknownHooks
Test-OmpHomeOverrideAndIdempotency
Test-CodexConfigIsPreserved
Write-Host "PASS: PowerShell sync regression checks"
