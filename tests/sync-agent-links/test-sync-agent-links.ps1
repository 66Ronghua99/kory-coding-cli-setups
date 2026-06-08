param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CuratedSkills = @(
    "using-superpowers",
    "brainstorming",
    "writing-plans",
    "executing-plans",
    "test-driven-development",
    "verification-before-completion"
)

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Exists {
    param([string]$Path)
    Assert-True (Test-Path -LiteralPath $Path) "Expected path to exist: $Path"
}

function Assert-NotExists {
    param([string]$Path)
    Assert-True (-not (Test-Path -LiteralPath $Path)) "Expected path to be absent: $Path"
}

function Assert-FileContains {
    param(
        [string]$Path,
        [string]$Expected
    )

    $content = Get-Content -Path $Path -Raw
    Assert-True ($content.Contains($Expected)) "Expected $Path to contain: $Expected"
}

function Assert-FileReflectsSource {
    param(
        [string]$Source,
        [string]$Target
    )

    Assert-Exists $Source
    Assert-Exists $Target

    $updated = [System.Guid]::NewGuid().ToString()
    Set-Content -Path $Source -Value $updated
    $targetContent = Get-Content -Path $Target -Raw
    Assert-True ($targetContent.Trim() -eq $updated) "Expected $Target to stay linked to $Source"
}

function Assert-FileContainsVersion {
    param(
        [string]$Path,
        [string]$Expected
    )

    Assert-FileContains -Path $Path -Expected "version: $Expected"
}

function New-SuperpowersRemote {
    param(
        [string]$RemoteRoot,
        [string]$Version
    )

    $bareRepo = Join-Path $RemoteRoot "superpowers-remote.git"
    $workRepo = Join-Path $RemoteRoot "work"

    git init --bare $bareRepo | Out-Null
    git clone $bareRepo $workRepo | Out-Null
    Push-Location $workRepo
    git config user.name "Test"
    git config user.email "test@example.com"
    foreach ($skill in $CuratedSkills) {
        New-Item -ItemType Directory -Force -Path (Join-Path $workRepo "skills\$skill") | Out-Null
        @"
---
name: $skill
description: test fixture
version: $Version
---
"@ | Set-Content -Path (Join-Path $workRepo "skills\$skill\SKILL.md")
    }
    "fixture $Version" | Set-Content -Path README.md
    git add README.md skills
    git commit -m "init $Version" | Out-Null
    git branch -M main | Out-Null
    git push origin main | Out-Null
    Pop-Location
}

function Update-SuperpowersRemote {
    param(
        [string]$RemoteRoot,
        [string]$Version
    )

    $bareRepo = Join-Path $RemoteRoot "superpowers-remote.git"
    $workRepo = Join-Path $RemoteRoot "update-work"

    git clone $bareRepo $workRepo | Out-Null
    Push-Location $workRepo
    git checkout main | Out-Null
    git config user.name "Test"
    git config user.email "test@example.com"
    foreach ($skill in $CuratedSkills) {
        @"
---
name: $skill
description: test fixture
version: $Version
---
"@ | Set-Content -Path (Join-Path $workRepo "skills\$skill\SKILL.md")
    }
    "fixture $Version" | Set-Content -Path README.md
    git add README.md skills
    git commit -m "update $Version" | Out-Null
    git push origin main | Out-Null
    Pop-Location
}

function New-FakeSource {
    param(
        [string]$SourceDir,
        [string]$RepoRoot
    )

    New-Item -ItemType Directory -Force -Path (Join-Path $SourceDir ".codex\agents") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $SourceDir "skills\sample-skill") | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot "sync-agent-links.ps1") -Destination (Join-Path $SourceDir "sync-agent-links.ps1")
    @"
# CLAUDE
"@ | Set-Content -Path (Join-Path $SourceDir "CLAUDE.md")
    @"
# AGENTS
"@ | Set-Content -Path (Join-Path $SourceDir "AGENTS.md")
    '{}' | Set-Content -Path (Join-Path $SourceDir "settings.json")
    'model = "gpt-5.4"' | Set-Content -Path (Join-Path $SourceDir ".codex\config.toml")
    'description = "explorer"' | Set-Content -Path (Join-Path $SourceDir ".codex\agents\explorer.toml")
    @"
---
name: sample-skill
description: sample
---
"@ | Set-Content -Path (Join-Path $SourceDir "skills\sample-skill\SKILL.md")
}

function Invoke-Sync {
    param(
        [string]$SourceDir,
        [string]$HomeDir,
        [string]$RemoteUrl,
        [string]$Branch = "main"
    )

    $env:SYNC_HOME = $HomeDir
    $env:SUPERPOWERS_REMOTE_URL = $RemoteUrl
    $env:SUPERPOWERS_BRANCH = $Branch
    try {
        & (Join-Path $SourceDir "sync-agent-links.ps1")
    } finally {
        Remove-Item Env:SYNC_HOME -ErrorAction SilentlyContinue
        Remove-Item Env:SUPERPOWERS_REMOTE_URL -ErrorAction SilentlyContinue
        Remove-Item Env:SUPERPOWERS_BRANCH -ErrorAction SilentlyContinue
    }
}

function Assert-CuratedSkillLinks {
    param([string]$SourceDir)

    foreach ($skill in $CuratedSkills) {
        $path = Join-Path $SourceDir "skills\$skill"
        Assert-Exists $path
    }
}

function Test-SyncClonesAndExportsCuratedSkills {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $remoteRoot = Join-Path $tempdir "remote"
    $remoteUrl = Join-Path $remoteRoot "superpowers-remote.git"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersRemote -RemoteRoot $remoteRoot -Version "v1"
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $homeDir -RemoteUrl $remoteUrl

    Assert-Exists (Join-Path $source "superpowers\.git")
    Assert-CuratedSkillLinks -SourceDir $source
    Assert-NotExists (Join-Path $source "skills\superpowers")
    Assert-Exists (Join-Path $homeDir ".claude\skills\sample-skill\SKILL.md")
    Assert-Exists (Join-Path $homeDir ".codex\skills\using-superpowers\SKILL.md")
    Assert-NotExists (Join-Path $homeDir ".codex\skills\skills")
    Assert-FileContainsVersion -Path (Join-Path $homeDir ".codex\skills\using-superpowers\SKILL.md") -Expected "v1"
    Assert-FileReflectsSource -Source (Join-Path $source "CLAUDE.md") -Target (Join-Path $homeDir ".claude\CLAUDE.md")
}

function Test-SyncPullsLatestSuperpowersContent {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $remoteRoot = Join-Path $tempdir "remote"
    $remoteUrl = Join-Path $remoteRoot "superpowers-remote.git"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersRemote -RemoteRoot $remoteRoot -Version "v1"
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $homeDir -RemoteUrl $remoteUrl
    Update-SuperpowersRemote -RemoteRoot $remoteRoot -Version "v2"
    Invoke-Sync -SourceDir $source -HomeDir $homeDir -RemoteUrl $remoteUrl

    Assert-FileContainsVersion -Path (Join-Path $source "superpowers\skills\using-superpowers\SKILL.md") -Expected "v2"
    Assert-FileContainsVersion -Path (Join-Path $homeDir ".claude\skills\using-superpowers\SKILL.md") -Expected "v2"
}

function Test-ConflictingTargetsAreBackedUp {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $remoteRoot = Join-Path $tempdir "remote"
    $remoteUrl = Join-Path $remoteRoot "superpowers-remote.git"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersRemote -RemoteRoot $remoteRoot -Version "v1"
    New-Item -ItemType Directory -Force -Path (Join-Path $homeDir ".claude") | Out-Null
    'old-claude' | Set-Content -Path (Join-Path $homeDir ".claude\CLAUDE.md")

    Invoke-Sync -SourceDir $source -HomeDir $homeDir -RemoteUrl $remoteUrl

    $backup = Get-ChildItem -LiteralPath (Join-Path $homeDir ".coding-cli-sync-backups") -Recurse -Filter "CLAUDE.md" | Select-Object -First 1
    Assert-True ($null -ne $backup) "Expected backup file for .claude/CLAUDE.md"
}

function Test-RerunIsIdempotent {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $remoteRoot = Join-Path $tempdir "remote"
    $remoteUrl = Join-Path $remoteRoot "superpowers-remote.git"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersRemote -RemoteRoot $remoteRoot -Version "v1"
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $homeDir -RemoteUrl $remoteUrl
    Invoke-Sync -SourceDir $source -HomeDir $homeDir -RemoteUrl $remoteUrl

    Assert-NotExists (Join-Path $homeDir ".coding-cli-sync-backups")
}

function Test-ExistingNonGitSuperpowersPathFails {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $remoteRoot = Join-Path $tempdir "remote"
    $remoteUrl = Join-Path $remoteRoot "superpowers-remote.git"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersRemote -RemoteRoot $remoteRoot -Version "v1"
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $source "superpowers") | Out-Null
    'not-a-git-repo' | Set-Content -Path (Join-Path $source "superpowers\README.txt")

    $failed = $false
    try {
        Invoke-Sync -SourceDir $source -HomeDir $homeDir -RemoteUrl $remoteUrl
    } catch {
        $failed = $true
        Assert-True $_.Exception.Message.Contains("not a git repository") "Expected invalid checkout guidance"
    }

    Assert-True $failed "Expected non-git superpowers path to fail"
}

function Test-LegacyNamespaceIsReplaced {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $remoteRoot = Join-Path $tempdir "remote"
    $remoteUrl = Join-Path $remoteRoot "superpowers-remote.git"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersRemote -RemoteRoot $remoteRoot -Version "v1"
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $source "superpowers\skills") | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path $source "skills\superpowers") -Target (Join-Path $source "superpowers\skills") | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $homeDir -RemoteUrl $remoteUrl

    Assert-NotExists (Join-Path $source "skills\superpowers")
    Assert-CuratedSkillLinks -SourceDir $source
}

function Test-InvalidRemoteFailsCleanly {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $invalidRemote = Join-Path $tempdir "does-not-exist.git"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    $failed = $false
    try {
        Invoke-Sync -SourceDir $source -HomeDir $homeDir -RemoteUrl $invalidRemote
    } catch {
        $failed = $true
    }

    Assert-True $failed "Expected invalid remote to fail"
}

Test-SyncClonesAndExportsCuratedSkills
Test-SyncPullsLatestSuperpowersContent
Test-ConflictingTargetsAreBackedUp
Test-RerunIsIdempotent
Test-ExistingNonGitSuperpowersPathFails
Test-LegacyNamespaceIsReplaced
Test-InvalidRemoteFailsCleanly

Write-Host "PASS: PowerShell sync regression checks"
