param(
  [switch]$RequireRepository
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
Push-Location $root
try {
  if ($RequireRepository) {
    $manifest = Get-Content -Raw -LiteralPath "moon.mod"
    if ($manifest -notmatch '(?m)^\s*repository\s*=\s*"https://github\.com/[^"]+"\s*$') {
      throw "moon.mod must contain a GitHub repository URL before release"
    }
  }

  $savedErrorPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $rawListing = @(& moon package --list 2>&1)
  $packageExitCode = $LASTEXITCODE
  $ErrorActionPreference = $savedErrorPreference
  if ($packageExitCode -ne 0) {
    throw "moon package --list failed"
  }
  $listing = @($rawListing | ForEach-Object { $_.ToString() })
  $listing | ForEach-Object { Write-Output $_ }
  $text = $listing -join "`n"

  $required = @(
    "LICENSE",
    "README.mbt.md",
    "pkg.generated.mbti",
    "cmd\uri-template\main.mbt"
  )
  foreach ($path in $required) {
    $pattern = "(?m)^" + [regex]::Escape($path) + "\r?$"
    if ($text -notmatch $pattern) {
      throw "Required publish file is missing: $path"
    }
  }

  $forbidden = @(
    "(?m)^testdata[\\/]",
    "(?m)^tools[\\/]",
    "(?m)^output[\\/]",
    "(?m)^examples[\\/]",
    "(?m)^.*_test\.mbt\r?$",
    "(?m)^.*_wbtest\.mbt\r?$",
    "(?m)^conformance_generated_wbtest\.mbt\r?$"
  )
  foreach ($pattern in $forbidden) {
    if ($text -match $pattern) {
      throw "Development-only content leaked into the publish archive: $($Matches[0])"
    }
  }

  Write-Output "Publish archive contents are valid."
} finally {
  Pop-Location
}
