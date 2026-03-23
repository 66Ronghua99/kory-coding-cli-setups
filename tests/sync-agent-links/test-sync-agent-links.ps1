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

function New-SuperpowersCheckout {
    param([string]$SourceDir)

    New-Item -ItemType Directory -Force -Path (Join-Path $SourceDir "superpowers\skills\using-superpowers") | Out-Null
    @"
---
name: using-superpowers
description: test fixture
---
"@ | Set-Content -Path (Join-Path $SourceDir "superpowers\skills\using-superpowers\SKILL.md")

    Push-Location (Join-Path $SourceDir "superpowers")
    git init | Out-Null
    git config user.name "Test"
    git config user.email "test@example.com"
    'fixture' | Set-Content -Path README.md
    git add README.md
    git commit -m "init" | Out-Null
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
        [switch]$UpdateSuperpowers
    )

    $env:SYNC_HOME = $HomeDir
    try {
        if ($UpdateSuperpowers) {
            & (Join-Path $SourceDir "sync-agent-links.ps1") -UpdateSuperpowers
        } else {
            & (Join-Path $SourceDir "sync-agent-links.ps1")
        }
    } finally {
        Remove-Item Env:SYNC_HOME -ErrorAction SilentlyContinue
    }
}

function Test-SyncsInitializedSuperpowersCheckout {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersCheckout -SourceDir $source
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $homeDir

    Assert-Exists (Join-Path $source "skills\superpowers\using-superpowers\SKILL.md")
    Assert-Exists (Join-Path $homeDir ".claude\skills\sample-skill\SKILL.md")
    Assert-Exists (Join-Path $homeDir ".codex\skills\skills\superpowers\using-superpowers\SKILL.md")
    Assert-FileReflectsSource -Source (Join-Path $source "CLAUDE.md") -Target (Join-Path $homeDir ".claude\CLAUDE.md")
}

function Test-ConflictingTargetsAreBackedUp {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersCheckout -SourceDir $source
    New-Item -ItemType Directory -Force -Path (Join-Path $homeDir ".claude") | Out-Null
    'old-claude' | Set-Content -Path (Join-Path $homeDir ".claude\CLAUDE.md")

    Invoke-Sync -SourceDir $source -HomeDir $homeDir

    $backup = Get-ChildItem -LiteralPath (Join-Path $homeDir ".coding-cli-sync-backups") -Recurse -Filter "CLAUDE.md" | Select-Object -First 1
    Assert-True ($null -ne $backup) "Expected backup file for .claude/CLAUDE.md"
}

function Test-RerunIsIdempotent {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersCheckout -SourceDir $source
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    Invoke-Sync -SourceDir $source -HomeDir $homeDir
    Invoke-Sync -SourceDir $source -HomeDir $homeDir

    Assert-NotExists (Join-Path $homeDir ".coding-cli-sync-backups")
}

function Test-MissingSuperpowersCheckoutFails {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    $failed = $false
    try {
        Invoke-Sync -SourceDir $source -HomeDir $homeDir
    } catch {
        $failed = $true
        Assert-True $_.Exception.Message.Contains("git submodule update --init --recursive") "Expected missing submodule guidance"
    }

    Assert-True $failed "Expected missing superpowers checkout to fail"
}

function Test-NonGitSuperpowersPathFails {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $source "superpowers\skills") | Out-Null
    'not-a-git-repo' | Set-Content -Path (Join-Path $source "superpowers\README.txt")

    $failed = $false
    try {
        Invoke-Sync -SourceDir $source -HomeDir $homeDir
    } catch {
        $failed = $true
    }

    Assert-True $failed "Expected non-git superpowers path to fail"
}

function Test-UpdateFlagFailsWithActionableMessage {
    $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    $source = Join-Path $tempdir "source"
    $homeDir = Join-Path $tempdir "home"
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    New-FakeSource -SourceDir $source -RepoRoot $repoRoot
    New-SuperpowersCheckout -SourceDir $source
    New-Item -ItemType Directory -Force -Path $homeDir | Out-Null

    $failed = $false
    try {
        Invoke-Sync -SourceDir $source -HomeDir $homeDir -UpdateSuperpowers
    } catch {
        $failed = $true
        Assert-True $_.Exception.Message.Contains("git submodule update --remote superpowers") "Expected manual submodule update guidance"
    }

    Assert-True $failed "Expected legacy update flag to fail"
}

Test-SyncsInitializedSuperpowersCheckout
Test-ConflictingTargetsAreBackedUp
Test-RerunIsIdempotent
Test-MissingSuperpowersCheckoutFails
Test-NonGitSuperpowersPathFails
Test-UpdateFlagFailsWithActionableMessage

Write-Host "PASS: PowerShell sync regression checks"
