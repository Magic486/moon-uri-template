param(
  [string]$ExpectedNamespace = "",
  [string]$ExpectedRepository = "",
  [switch]$RequireReleaseMetadata,
  [switch]$SkipDifferential,
  [switch]$AllowDirty
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$manifestPath = Join-Path $root "moon.mod"

function Read-ManifestString([string]$Key) {
  $pattern = "^\s*" + [regex]::Escape($Key) + "\s*=\s*`"([^`"]*)`"\s*$"
  foreach ($line in Get-Content -LiteralPath $manifestPath) {
    if ($line -match $pattern) {
      return $Matches[1]
    }
  }
  throw "Missing string field '$Key' in moon.mod"
}

function Invoke-Step([string]$Name, [scriptblock]$Action) {
  Write-Output ""
  Write-Output "==> $Name"
  & $Action
  if ($LASTEXITCODE -ne 0) {
    throw "$Name failed with exit code $LASTEXITCODE"
  }
}

Push-Location $root
try {
  $initialStatus = @(git status --porcelain)
  if (!$AllowDirty -and $initialStatus.Count -ne 0) {
    throw "Release preflight requires a clean Git worktree"
  }

  $name = Read-ManifestString "name"
  $version = Read-ManifestString "version"
  $repository = Read-ManifestString "repository"
  if ($name -notmatch "^[A-Za-z0-9_-]+/[A-Za-z0-9_-]+$") {
    throw "Invalid mooncakes namespace: $name"
  }
  if ($version -notmatch "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[0-9A-Za-z.-]+)?$") {
    throw "Version is not valid semantic version syntax: $version"
  }
  if ($ExpectedNamespace -ne "" -and $name -ne $ExpectedNamespace) {
    throw "Expected namespace '$ExpectedNamespace', found '$name'"
  }
  if ($ExpectedRepository -ne "" -and $repository -ne $ExpectedRepository) {
    throw "Expected repository '$ExpectedRepository', found '$repository'"
  }
  if ($RequireReleaseMetadata) {
    if ($ExpectedNamespace -eq "" -or $ExpectedRepository -eq "") {
      throw "Release mode requires -ExpectedNamespace and -ExpectedRepository"
    }
    if ($repository -notmatch "^https://github\.com/[^/]+/[^/]+(?:\.git)?$") {
      throw "Release repository must be a public GitHub HTTPS URL"
    }
  }

  Invoke-Step "Regenerate conformance evidence" {
    powershell -NoProfile -ExecutionPolicy Bypass `
      -File tools/generate_conformance_tests.ps1
    if ($LASTEXITCODE -ne 0) {
      throw "Conformance generator failed"
    }
    moon fmt conformance_generated_wbtest.mbt
  }
  Invoke-Step "Check formatting" { moon fmt --check }
  Invoke-Step "Check warnings and types" {
    moon check --warn-list +73 --deny-warn
  }
  Invoke-Step "Generate and review public API summary" { moon info }
  Invoke-Step "Build every supported backend" { moon build --target all }
  Invoke-Step "Test every supported backend" { moon test --target all }
  Invoke-Step "Verify publish archive contents" {
    $packageCheckArgs = @(
      "-NoProfile",
      "-ExecutionPolicy",
      "Bypass",
      "-File",
      "tools/check_package_contents.ps1"
    )
    if ($RequireReleaseMetadata) {
      $packageCheckArgs += "-RequireRepository"
    }
    powershell @packageCheckArgs
  }

  if (!$SkipDifferential) {
    $python = if ($env:DIFFERENTIAL_PYTHON) {
      $env:DIFFERENTIAL_PYTHON
    } elseif (Test-Path ".venv\Scripts\python.exe") {
      ".venv\Scripts\python.exe"
    } else {
      "python"
    }
    Invoke-Step "Check differential-test dependencies" {
      & $python -c "import uritemplate, stduritemplate"
    }
    Invoke-Step "Run differential suite" {
      & $python tools/differential/compare.py
    }
  }

  $proposal = "output\pdf\moon-uri-template-project-proposal.pdf"
  if (!(Test-Path $proposal) -or (Get-Item $proposal).Length -lt 10000) {
    throw "The one-page proposal PDF is missing or unexpectedly small"
  }
  if (!$AllowDirty) {
    $finalStatus = @(git status --porcelain)
    if ($finalStatus.Count -ne 0) {
      throw "Preflight changed tracked files; regenerate and commit them first"
    }
  }
  Write-Output ""
  Write-Output "Release preflight passed for $name@$version."
  if (!$RequireReleaseMetadata) {
    Write-Output "Metadata was checked in development mode; no upload was attempted."
  }
} finally {
  Pop-Location
}
