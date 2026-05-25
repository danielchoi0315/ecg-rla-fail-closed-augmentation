param(
  [string]$ManifestPath = "metadata/file_manifest_sha256.csv"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$manifestFull = Join-Path $root $ManifestPath

if (-not (Test-Path -LiteralPath $manifestFull)) {
  throw "Manifest not found: $manifestFull"
}

$manifest = Import-Csv -LiteralPath $manifestFull
$failures = New-Object System.Collections.Generic.List[string]

foreach ($row in $manifest) {
  $path = Join-Path $root $row.path
  if (-not (Test-Path -LiteralPath $path)) {
    $failures.Add("Missing file: $($row.path)")
    continue
  }
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
  $expected = $row.sha256.ToLowerInvariant()
  if ($actual -ne $expected) {
    $failures.Add("Hash mismatch: $($row.path)")
  }
}

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Error $_ }
  throw "Integrity check failed with $($failures.Count) issue(s)."
}

Write-Host "Integrity check passed for $($manifest.Count) files."

