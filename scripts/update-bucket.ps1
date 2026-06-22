param(
    [string]$BucketDir = ".",
    [string[]]$Exclude = @(),
    [switch]$CheckOnly,
    [switch]$Commit,
    [switch]$Push
)

$ErrorActionPreference = "Stop"

function Resolve-BucketRoot {
    param([string]$Path)

    $resolved = Resolve-Path $Path
    $dir = Get-Item $resolved

    if ($dir.Name -eq "bucket") {
        return $dir.Parent.FullName
    }

    return $dir.FullName
}

function Get-ScoopHome {
    if ($env:SCOOP_HOME -and (Test-Path "$env:SCOOP_HOME\bin\checkver.ps1")) {
        return $env:SCOOP_HOME
    }

    $scoopHome = (& scoop prefix scoop 2>$null).Trim()
    if (-not $scoopHome -or -not (Test-Path "$scoopHome\bin\checkver.ps1")) {
        throw "Cannot find Scoop checkver.ps1. Please make sure Scoop is installed correctly."
    }

    return $scoopHome
}

$bucketRoot = Resolve-BucketRoot $BucketDir
$manifestDir = Join-Path $bucketRoot "bucket"

if (-not (Test-Path $manifestDir)) {
    throw "Invalid bucket directory: $bucketRoot. Missing bucket\ directory."
}

$scoopHome = Get-ScoopHome
$checkver = Join-Path $scoopHome "bin\checkver.ps1"

Write-Host "Bucket: $bucketRoot" -ForegroundColor Cyan
Write-Host "Checkver: $checkver" -ForegroundColor Cyan

$apps = Get-ChildItem $manifestDir -Filter "*.json" |
    Sort-Object BaseName |
    Where-Object { $Exclude -notcontains $_.BaseName }

if ($apps.Count -eq 0) {
    Write-Host "No manifests found." -ForegroundColor Yellow
    exit 0
}

$failed = @()
$updated = @()

foreach ($app in $apps) {
    $name = $app.BaseName
    Write-Host ""
    Write-Host "==> $name" -ForegroundColor Green

    try {
        if ($CheckOnly) {
            & $checkver -App $name -Dir $bucketRoot
        } else {
            & $checkver -App $name -Dir $bucketRoot -Update
        }

        if ($LASTEXITCODE -ne 0) {
            throw "checkver exited with code $LASTEXITCODE"
        }

        $updated += $name
    } catch {
        Write-Host "FAILED: $name" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $failed += $name
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
Write-Host "Succeeded: $($updated.Count)"
Write-Host "Failed: $($failed.Count)"

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed apps:" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

Push-Location $bucketRoot
try {
    Write-Host ""
    git status --short

    if ($Commit) {
        $changes = git status --porcelain
        if ($changes) {
            git add bucket
            git commit -m "Update Scoop manifests"
        } else {
            Write-Host "No changes to commit." -ForegroundColor Yellow
        }
    }

    if ($Push) {
        git push
    }
} finally {
    Pop-Location
}
