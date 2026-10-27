# Downloads every logo in logos.csv into .\images, named after the school
# (lowercase, underscores). Standard logo -> <school>.png, dark variant -> <school>_dark.png
# Usage:  powershell -ExecutionPolicy Bypass -File .\download-logos.ps1

$ProgressPreference = 'SilentlyContinue'   # makes Invoke-WebRequest much faster
$root = $PSScriptRoot
$out  = Join-Path $root 'images'
New-Item -ItemType Directory -Force -Path $out | Out-Null

function Get-Slug([string]$name) {
    $s = $name.Normalize([Text.NormalizationForm]::FormD) -replace '\p{Mn}', ''   # José -> Jose
    $s = $s.ToLower() -replace "[&'’.]", ''          # Texas A&M -> texas am, St. -> st
    return ($s -replace '[^a-z0-9]+', '_').Trim('_')    # everything else -> underscore
}

# logos.csv is Latin-1 encoded (e.g. "San José State"), so read it that way
# Open with FileShare.ReadWrite so this still works while the CSV is open in Excel
$fs = [IO.File]::Open((Join-Path $root 'logos.csv'), 'Open', 'Read', 'ReadWrite')
try {
    $reader = New-Object IO.StreamReader($fs, [Text.Encoding]::GetEncoding('iso-8859-1'))
    $text = $reader.ReadToEnd()
} finally { $fs.Dispose() }
$rows = $text | ConvertFrom-Csv
$ok = 0; $skipped = 0; $failed = @()

foreach ($r in $rows) {
    $slug = Get-Slug $r.school
    $targets = @(
        @{ Url = $r.logo;        File = "$slug.png" },
        @{ Url = $r.'logos[1]';  File = "${slug}_dark.png" }
    )
    foreach ($t in $targets) {
        if ([string]::IsNullOrWhiteSpace($t.Url)) { continue }
        $dest = Join-Path $out $t.File
        if (Test-Path $dest) { $skipped++; continue }
        $url = $t.Url -replace '^http://', 'https://'
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 30
            $ok++
            Write-Host "OK   $($t.File)"
        } catch {
            $failed += "$($r.school) -> $url"
            Write-Warning "FAIL $($t.File): $($_.Exception.Message)"
        }
    }
}

Write-Host ""
Write-Host "Downloaded: $ok   Already existed: $skipped   Failed: $($failed.Count)"
if ($failed.Count) { $failed | Set-Content (Join-Path $root 'failed-downloads.txt'); Write-Host "See failed-downloads.txt" }
