param(
    [Parameter(Mandatory = $true)]
    [string]$Plan
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PrimaryModel = "gpt-5.6-sol"
$FallbackModel = "gpt-5.5"
$PromptPath = Join-Path (Split-Path -Parent $PSScriptRoot) "codex-review-prompt.md"
$CodexBin = if ($env:CODEX_BIN) { $env:CODEX_BIN } else { "codex" }

function Exit-Usage {
    param([string]$Message)
    [Console]::Error.WriteLine("Error: $Message")
    exit 64
}

function Write-Status {
    param([string]$Status, [string]$Model, [string]$Reason = "")
    if ($Reason) {
        [Console]::Out.WriteLine("EXECUTING_PLANS_REVIEW_STATUS=$Status MODEL=$Model REASON=$Reason")
    } else {
        [Console]::Out.WriteLine("EXECUTING_PLANS_REVIEW_STATUS=$Status MODEL=$Model")
    }
}

if (-not (Test-Path -LiteralPath $Plan -PathType Leaf)) { Exit-Usage "plan is not readable: $Plan" }
if (-not (Test-Path -LiteralPath $PromptPath -PathType Leaf)) { Exit-Usage "review prompt is not readable: $PromptPath" }
$PlanPath = (Resolve-Path -LiteralPath $Plan).Path
$Context = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($Context)) { Exit-Usage "stdin review context is required" }

$PlanText = Get-Content -LiteralPath $PlanPath -Raw
$ParseText = [regex]::Replace(
    $PlanText,
    '(?ms)^(?<fence>`{3,}|~{3,})[^\r\n]*\r?\n.*?^\k<fence>[ \t]*\r?$',
    ''
)
$TaskMatches = [regex]::Matches($ParseText, '(?ms)^### Task (?<id>\d+):[^\r\n]*\r?\n(?<body>.*?)(?=^### Task \d+:|\z)')
if ($TaskMatches.Count -eq 0) { Exit-Usage "plan contains no task headings" }

$ExpectedTasks = @()
foreach ($TaskMatch in $TaskMatches) {
    $Id = $TaskMatch.Groups["id"].Value
    $Body = $TaskMatch.Groups["body"].Value
    $Execution = [regex]::Match($Body, '(?m)^\*\*Execution:\*\* (\[[ x]\] complete)$')
    $Verification = [regex]::Match($Body, '(?m)^\*\*Codex verification:\*\* (.+)$')
    if (-not $Execution.Success -or -not $Verification.Success) {
        Exit-Usage "Task $Id is missing execution or Codex verification state"
    }
    if ($Execution.Groups[1].Value -ne "[x] complete") {
        Exit-Usage "Task $Id execution is incomplete"
    }
    $IsVerified = [regex]::IsMatch(
        $Verification.Groups[1].Value,
        '^VERIFIED \(round \d+, (gpt-5\.6-sol|gpt-5\.5)\)$'
    )
    if (-not $IsVerified) { $ExpectedTasks += $Id }
}
if ($ExpectedTasks.Count -eq 0) { Exit-Usage "plan has no pending tasks to review" }

$Prompt = Get-Content -LiteralPath $PromptPath -Raw
$RequestText = @"
$Prompt

# Runtime Review Input

Plan path: $PlanPath
Expected task IDs: $($ExpectedTasks -join ',')

Completion context:
$Context
"@

$CodexCommand = Get-Command $CodexBin -ErrorAction SilentlyContinue
if ($null -eq $CodexCommand) {
    Write-Status -Status "SKIPPED" -Model "none" -Reason "codex-cli-unavailable"
    exit 2
}
$CodexPath = $CodexCommand.Source

function Invoke-CodexModel {
    param([string]$Model)
    $Arguments = @(
        "review",
        "--uncommitted",
        "-c", "model=`"$Model`"",
        "-c", 'model_reasoning_effort="high"',
        "-"
    )
    $RawObjects = @($RequestText | & $CodexPath @Arguments 2>&1)
    $ExitCode = $LASTEXITCODE
    $Raw = ($RawObjects | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    if ($Raw) { [Console]::Out.WriteLine($Raw) }
    return @{ ExitCode = $ExitCode; Raw = $Raw }
}

function Test-FallbackError {
    param([string]$Text)
    return [regex]::IsMatch(
        $Text,
        'rate.?limit|quota|usage limit|too many requests|model.*(unavailable|not available|not found|unsupported|does not exist)|unsupported.*model',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
}

function Test-Protocol {
    param([string]$Text)
    $Verdicts = [regex]::Matches($Text, '(?m)^VERDICT: (PASS|BLOCKED)$')
    if ($Verdicts.Count -ne 1) { return @{ State = "MALFORMED" } }

    $TaskVerdicts = [regex]::Matches($Text, '(?m)^- Task (?<id>\d+): (?<state>VERIFIED|BLOCKED)$')
    if ($TaskVerdicts.Count -ne $ExpectedTasks.Count) { return @{ State = "MALFORMED" } }
    foreach ($Expected in $ExpectedTasks) {
        $Count = @($TaskVerdicts | Where-Object { $_.Groups["id"].Value -eq $Expected }).Count
        if ($Count -ne 1) { return @{ State = "MALFORMED" } }
    }
    foreach ($Observed in $TaskVerdicts) {
        if ($ExpectedTasks -notcontains $Observed.Groups["id"].Value) { return @{ State = "MALFORMED" } }
    }

    $BlockedVerdicts = @($TaskVerdicts | Where-Object { $_.Groups["state"].Value -eq "BLOCKED" })
    $PriorityFindings = [regex]::Matches($Text, '(?m)^- \[P[01]\] Task (?<id>\d+) ')
    foreach ($Finding in $PriorityFindings) {
        $MatchingBlocked = @($BlockedVerdicts | Where-Object {
            $_.Groups["id"].Value -eq $Finding.Groups["id"].Value
        }).Count
        if ($MatchingBlocked -ne 1) { return @{ State = "MALFORMED" } }
    }
    foreach ($Blocked in $BlockedVerdicts) {
        $MatchingFinding = @($PriorityFindings | Where-Object {
            $_.Groups["id"].Value -eq $Blocked.Groups["id"].Value
        }).Count
        if ($MatchingFinding -eq 0) { return @{ State = "MALFORMED" } }
    }
    $HasBlocked = $BlockedVerdicts.Count -gt 0
    $HasP01 = $PriorityFindings.Count -gt 0
    $Verdict = $Verdicts[0].Groups[1].Value
    if ($Verdict -eq "PASS") {
        if ($HasBlocked -or $HasP01) { return @{ State = "MALFORMED" } }
        return @{ State = "PASS" }
    }
    if (-not $HasBlocked -and -not $HasP01) { return @{ State = "MALFORMED" } }
    return @{ State = "BLOCKED" }
}

function Review-Model {
    param([string]$Model, [bool]$AllowFallback)
    foreach ($Attempt in 1..2) {
        $Invocation = Invoke-CodexModel -Model $Model
        if ($Invocation.ExitCode -ne 0) {
            if ($AllowFallback -and (Test-FallbackError -Text $Invocation.Raw)) {
                return @{ State = "FALLBACK"; Model = $Model; Reason = "primary-model-or-quota-unavailable" }
            }
            return @{ State = "SKIPPED"; Model = $Model; Reason = "codex-unavailable" }
        }
        $Protocol = Test-Protocol -Text $Invocation.Raw
        if ($Protocol.State -eq "PASS" -or $Protocol.State -eq "BLOCKED") {
            return @{ State = $Protocol.State; Model = $Model; Reason = "" }
        }
    }
    return @{ State = "SKIPPED"; Model = $Model; Reason = "malformed-output" }
}

$Result = Review-Model -Model $PrimaryModel -AllowFallback $true
if ($Result.State -eq "FALLBACK") {
    $Result = Review-Model -Model $FallbackModel -AllowFallback $false
}

switch ($Result.State) {
    "PASS" {
        Write-Status -Status "PASS" -Model $Result.Model
        exit 0
    }
    "BLOCKED" {
        Write-Status -Status "BLOCKED" -Model $Result.Model
        exit 1
    }
    default {
        Write-Status -Status "SKIPPED" -Model $Result.Model -Reason $Result.Reason
        exit 2
    }
}
