$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifest = Join-Path $root "metadata/file_manifest_sha256.csv"

$files = Get-ChildItem -Path $root -Recurse -File -Force | Where-Object {
  $relative = $_.FullName.Substring($root.Length + 1).Replace("\", "/")
  $_.FullName -notmatch "\\.git(\\|$)" -and
  $relative -ne "metadata/file_manifest_sha256.csv" -and
  $relative -notmatch "^figures/" -and
  $relative -notmatch "^manuscript/"
} | Sort-Object FullName

$rows = foreach ($file in $files) {
  [pscustomobject]@{
    path = $file.FullName.Substring($root.Length + 1).Replace("\", "/")
    bytes = $file.Length
    sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant()
  }
}

$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $manifest
Write-Host "Wrote $($rows.Count) manifest rows to $manifest"

