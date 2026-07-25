$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))

function Invoke-Cli([string[]]$Arguments) {
  $savedErrorPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $rawOutput = @(& moon run cmd/uri-template -- @Arguments 2>&1)
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $savedErrorPreference
  $lines = @($rawOutput | ForEach-Object { $_.ToString() })
  $stdout = @($lines | Where-Object {
    $_ -notmatch "^Finished\. moon:" -and
    $_ -notmatch "^\s*$"
  })
  @{
    ExitCode = $exitCode
    Output = $stdout
  }
}

function Assert-Result(
  [string]$Name,
  [hashtable]$Result,
  [int]$ExitCode,
  [string[]]$ExpectedOutput
) {
  if ($Result.ExitCode -ne $ExitCode) {
    throw "$Name exited $($Result.ExitCode), expected $ExitCode"
  }
  $actual = $Result.Output -join "`n"
  $expected = $ExpectedOutput -join "`n"
  if ($actual -ne $expected) {
    throw "$Name output mismatch.`nExpected:`n$expected`nActual:`n$actual"
  }
}

Push-Location $root
try {
  Assert-Result "validate" `
    (Invoke-Cli @("validate", "/repos/{owner}/{repo}{?page}")) `
    0 `
    @("valid RFC 6570 Level 3 template; 3 variable(s)")
  Assert-Result "variables" `
    (Invoke-Cli @("variables", "/repos/{owner}/{repo}{?page}")) `
    0 `
    @("owner", "repo", "page")
  Assert-Result "expand" `
    (Invoke-Cli @(
      "expand",
      "/repos/{owner}/{repo}/issues{?page,labels*}",
      "--variables",
      "examples/variables.json"
    )) `
    0 `
    @("/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted")
  Assert-Result "invalid template" `
    (Invoke-Cli @("validate", "{unclosed")) `
    1 `
    @("error: URI Template syntax error at 0: unclosed expression")

  $unknown = Invoke-Cli @("unknown", "{x}")
  if ($unknown.ExitCode -ne 2 -or $unknown.Output[0] -ne "error: unknown command: unknown") {
    throw "unknown command did not return the documented invocation error"
  }
  Write-Output "CLI smoke tests passed."
  exit 0
} finally {
  Pop-Location
}
