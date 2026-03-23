param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function New-SuperpowersRemote {
    param([string]$RemoteRoot)

    $worktree = Join-Path $RemoteRoot "work"
    $bare = Join-Path $RemoteRoot "remote.git"
    New-Item -ItemType Directory -Force -Path (Join-Path $worktree "skills\using-superpowers") | Out-Null
    @"
---
name: using-superpowers
description: test fixture
---
"@ | Set-Content -Path (Join-Path $worktree "skills\using-superpowers\SKILL.md")

    Push-Location $worktree
    git init | Out-Null
    git config user.name "Test"
    git config user.email "test@example.com"
    git add "skills/using-superpowers/SKILL.md"
    git commit -m "init" | Out-Null
    git branch -M main
    git init --bare $bare | Out-Null
    git remote add origin $bare
    git push -u origin main | Out-Null
    Pop-Location

    git -C $bare symbolic-ref HEAD refs/heads/main | Out-Null
    return $bare
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
        [string]$Remote,
        [switch]$UpdateSuperpowers
    )

    $env:SYNC_HOME = $HomeDir
    $env:SUPERPOWERS_REMOTE_URL = $Remote
    try {
        if ($UpdateSuperpowers) {
            & (Join-Path $SourceDir "sync-agent-links.ps1") -UpdateSuperpowers
        } else {
            & (Join-Path $SourceDir "sync-agent-links.ps1")
        }
    } finally {
        Remove-Item Env:SYNC_HOME -ErrorAction SilentlyContinue
        Remove-Item Env:SUPERPOWERS_REMOTE_URL -ErrorAction SilentlyContinue
    }
}

function Test-BootstrapsSuperpowersAndSyncsTargets {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $home = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $remote = New-SuperpowersRemote -RemoteRoot (Join-Path $tempdir "remote")
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $home | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $home -Remote $remote

    Assert-Exists (Join-Path $source "superpowers\.git")
    Assert-Exists (Join-Path $source "skills\superpowers\using-superpowers\SKILL.md")
    Assert-Exists (Join-Path $home ".claude\skills\sample-skill\SKILL.md")
    Assert-Exists (Join-Path $home ".codex\skills\skills\sample-skill\SKILL.md")
}

function Test-UpdateModeFastForwardsCheckout {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $home = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $remoteRoot = Join-Path $tempdir "remote"
    $remote = New-SuperpowersRemote -RemoteRoot $remoteRoot
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $home | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $home -Remote $remote

    'updated' | Set-Content -Path (Join-Path $remoteRoot "work\skills\using-superpowers\UPDATED.md")
    Push-Location (Join-Path $remoteRoot "work")
    git add "skills/using-superpowers/UPDATED.md"
    git commit -m "update" | Out-Null
    git push | Out-Null
    Pop-Location

    Invoke-Sync -SourceDir $source -HomeDir $home -Remote $remote -UpdateSuperpowers

    Assert-Exists (Join-Path $source "superpowers\skills\using-superpowers\UPDATED.md")
}

function Test-ConflictingTargetsAreBackedUp {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $home = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $remote = New-SuperpowersRemote -RemoteRoot (Join-Path $tempdir "remote")
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path (Join-Path $home ".claude") | Out-Null
    'old-claude' | Set-Content -Path (Join-Path $home ".claude\CLAUDE.md")

    Invoke-Sync -SourceDir $source -HomeDir $home -Remote $remote

    $backup = Get-ChildItem -LiteralPath (Join-Path $home ".coding-cli-sync-backups") -Recurse -Filter "CLAUDE.md" | Select-Object -First 1
    Assert-True ($null -ne $backup) "Expected backup file for .claude/CLAUDE.md"
}

function Test-RerunIsIdempotent {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $home = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $remote = New-SuperpowersRemote -RemoteRoot (Join-Path $tempdir "remote")
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $home | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $home -Remote $remote
    Invoke-Sync -SourceDir $source -HomeDir $home -Remote $remote

    Assert-NotExists (Join-Path $home ".coding-cli-sync-backups")
}

function Test-NonGitSuperpowersPathFails {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $home = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $remote = New-SuperpowersRemote -RemoteRoot (Join-Path $tempdir "remote")
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $home | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $source "superpowers") | Out-Null
    'not-a-git-repo' | Set-Content -Path (Join-Path $source "superpowers\README.txt")

    $failed = $false
    try {
        Invoke-Sync -SourceDir $source -HomeDir $home -Remote $remote
    } catch {
        $failed = $true
    }

    Assert-True $failed "Expected non-git superpowers path to fail"
}

function Test-EmptySuperpowersDirectoryBootstrapsSuccessfully {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $home = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $remote = New-SuperpowersRemote -RemoteRoot (Join-Path $tempdir "remote")
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $home | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $source "superpowers") | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $home -Remote $remote

    Assert-Exists (Join-Path $source "superpowers\.git")
    Assert-Exists (Join-Path $source "skills\superpowers\using-superpowers\SKILL.md")
}

Test-BootstrapsSuperpowersAndSyncsTargets
Test-UpdateModeFastForwardsCheckout
Test-ConflictingTargetsAreBackedUp
Test-RerunIsIdempotent
Test-NonGitSuperpowersPathFails
Test-EmptySuperpowersDirectoryBootstrapsSuccessfully

Write-Host "PASS: PowerShell sync regression checks"
