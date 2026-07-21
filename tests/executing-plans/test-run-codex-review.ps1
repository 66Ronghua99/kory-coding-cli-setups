param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Runner = Join-Path $RepoRoot "skills\executing-plans\scripts\run-codex-review.ps1"
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Contains {
    param([string]$Text, [string]$Expected)
    Assert-True $Text.Contains($Expected) "Expected output to contain: $Expected`n$Text"
}

try {
    $Plan = Join-Path $TempDir "plan.md"
    @'
### Task 1: Parser

**Execution:** [x] complete
**Codex verification:** PENDING

### Task 2: Sync

**Execution:** [x] complete
**Codex verification:** PENDING

~~~~markdown
### Task 99: Documentation example

**Execution:** [x] complete
**Codex verification:** PENDING
~~~~
'@ | Set-Content -LiteralPath $Plan -NoNewline

    $FakePs1 = Join-Path $TempDir "fake-codex.ps1"
    @'
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$Rest = @($args)
$CountFile = Join-Path $env:FAKE_CAPTURE_DIR "count"
$Count = if (Test-Path -LiteralPath $CountFile) { [int](Get-Content -LiteralPath $CountFile -Raw) } else { 0 }
$Count += 1
Set-Content -LiteralPath $CountFile -Value $Count -NoNewline
Add-Content -LiteralPath (Join-Path $env:FAKE_CAPTURE_DIR "args") -Value ($Rest -join " ")
[Console]::In.ReadToEnd() | Set-Content -LiteralPath (Join-Path $env:FAKE_CAPTURE_DIR "request.$Count") -NoNewline

$Pass = @"
TASK_VERDICTS:
- Task 1: VERIFIED
- Task 2: VERIFIED

FINDINGS:
none

P2_NOTES:
none

VERDICT: PASS
"@

switch ($env:FAKE_SCENARIO) {
    "pass" { [Console]::Out.WriteLine($Pass); exit 0 }
    "blocked" {
        [Console]::Out.WriteLine(@"
TASK_VERDICTS:
- Task 1: VERIFIED
- Task 2: BLOCKED

FINDINGS:
- [P1] Task 2 — sync.ps1:20 — required mapping is absent — add the mapping

P2_NOTES:
none

VERDICT: BLOCKED
"@)
        exit 0
    }
    "p2" {
        [Console]::Out.WriteLine(@"
TASK_VERDICTS:
- Task 1: VERIFIED
- Task 2: VERIFIED

FINDINGS:
none

P2_NOTES:
- [P2] Task 1 — parser.test.ps1:10 — fixture name is unclear — rename it later

VERDICT: PASS
"@)
        exit 0
    }
    "fallback" {
        if (($Rest -join " ").Contains("gpt-5.6-sol")) {
            [Console]::Error.WriteLine("rate limit reached for model gpt-5.6-sol")
            exit 1
        }
        [Console]::Out.WriteLine($Pass)
        exit 0
    }
    "malformed" { [Console]::Out.WriteLine("VERDICT: PASS"); exit 0 }
    "inconsistent" {
        [Console]::Out.WriteLine(@"
TASK_VERDICTS:
- Task 1: VERIFIED
- Task 2: BLOCKED

FINDINGS:
- [P1] Task 1 — parser.ps1:20 — finding conflicts with task verdict — correct the verdict

P2_NOTES:
none

VERDICT: BLOCKED
"@)
        exit 0
    }
    default { [Console]::Error.WriteLine("unknown fake scenario"); exit 9 }
}
'@ | Set-Content -LiteralPath $FakePs1 -NoNewline

    $FakeCmd = Join-Path $TempDir "fake-codex.cmd"
    @"
@echo off
pwsh -NoProfile -File "$FakePs1" %*
exit /b %ERRORLEVEL%
"@ | Set-Content -LiteralPath $FakeCmd -NoNewline

    function Invoke-Case {
        param([string]$Scenario)
        Remove-Item -LiteralPath (Join-Path $TempDir "count") -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $TempDir "args") -ErrorAction SilentlyContinue
        Get-ChildItem -LiteralPath $TempDir -Filter "request.*" -ErrorAction SilentlyContinue | Remove-Item
        $env:FAKE_CAPTURE_DIR = $TempDir
        $env:FAKE_SCENARIO = $Scenario
        $env:CODEX_BIN = $FakeCmd
        try {
            $Output = "goal: execute plan`nself-check: verification passed" |
                & pwsh -NoProfile -File $Runner -Plan $Plan 2>&1 | Out-String
            $Code = $LASTEXITCODE
            return @{ Output = $Output; Code = $Code }
        } finally {
            Remove-Item Env:FAKE_CAPTURE_DIR -ErrorAction SilentlyContinue
            Remove-Item Env:FAKE_SCENARIO -ErrorAction SilentlyContinue
            Remove-Item Env:CODEX_BIN -ErrorAction SilentlyContinue
        }
    }

    $Result = Invoke-Case "pass"
    Assert-True ($Result.Code -eq 0) "PASS scenario returned $($Result.Code)"
    Assert-Contains $Result.Output "EXECUTING_PLANS_REVIEW_STATUS=PASS MODEL=gpt-5.6-sol"
    Assert-Contains (Get-Content -LiteralPath (Join-Path $TempDir "request.1") -Raw) "Expected task IDs: 1,2"

    $Result = Invoke-Case "blocked"
    Assert-True ($Result.Code -eq 1) "BLOCKED scenario returned $($Result.Code)"
    Assert-Contains $Result.Output "EXECUTING_PLANS_REVIEW_STATUS=BLOCKED MODEL=gpt-5.6-sol"

    $Result = Invoke-Case "p2"
    Assert-True ($Result.Code -eq 0) "P2 scenario returned $($Result.Code)"
    Assert-Contains $Result.Output "[P2] Task 1"

    $Result = Invoke-Case "fallback"
    Assert-True ($Result.Code -eq 0) "fallback scenario returned $($Result.Code)"
    Assert-Contains $Result.Output "EXECUTING_PLANS_REVIEW_STATUS=PASS MODEL=gpt-5.5"
    $ArgsLog = Get-Content -LiteralPath (Join-Path $TempDir "args") -Raw
    Assert-Contains $ArgsLog "gpt-5.6-sol"
    Assert-Contains $ArgsLog "gpt-5.5"

    foreach ($Scenario in @("malformed", "inconsistent")) {
        $Result = Invoke-Case $Scenario
        Assert-True ($Result.Code -eq 2) "$Scenario scenario returned $($Result.Code)"
        Assert-Contains $Result.Output "REASON=malformed-output"
        Assert-True ((Get-Content -LiteralPath (Join-Path $TempDir "count") -Raw) -eq "2") "$Scenario output should retry once"
    }

    $env:CODEX_BIN = Join-Path $TempDir "missing-codex.exe"
    try {
        $MissingOutput = "review context" | & pwsh -NoProfile -File $Runner -Plan $Plan 2>&1 | Out-String
        $MissingCode = $LASTEXITCODE
    } finally {
        Remove-Item Env:CODEX_BIN -ErrorAction SilentlyContinue
    }
    Assert-True ($MissingCode -eq 2) "missing Codex returned $MissingCode"
    Assert-Contains $MissingOutput "REASON=codex-cli-unavailable"

    Write-Host "PASS: PowerShell Codex review runner"
} finally {
    Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
