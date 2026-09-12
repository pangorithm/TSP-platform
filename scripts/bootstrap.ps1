[CmdletBinding()]
param(
    [string]$WorkspaceRoot
)

$ErrorActionPreference = "Stop"
$RepositoryRoot = Split-Path -Parent $PSScriptRoot
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Split-Path -Parent $RepositoryRoot
}

$ManifestPath = Join-Path $RepositoryRoot "repositories.json"
$Manifest = Get-Content -Raw $ManifestPath | ConvertFrom-Json

if ($Manifest.schemaVersion -ne 1 -or -not $Manifest.repositories) {
    throw "repositories.json does not match schema version 1."
}

foreach ($Repository in $Manifest.repositories) {
    $Target = Join-Path $WorkspaceRoot $Repository.name
    $GitDirectory = Join-Path $Target ".git"

    if (Test-Path $GitDirectory -PathType Container) {
        $Origin = (& git -C $Target remote get-url origin).Trim()
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to read $($Repository.name) origin."
        }
        if ($Origin -ne $Repository.httpsUrl -and $Origin -ne $Repository.sshUrl) {
            throw "$($Repository.name) origin mismatch: $Origin"
        }
        Write-Host "$($Repository.name): existing checkout verified"
        continue
    }

    if (Test-Path $Target) {
        throw "$Target exists but is not a Git checkout."
    }

    & git clone --branch $Repository.defaultBranch $Repository.sshUrl $Target
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to clone $($Repository.name)."
    }
    Write-Host "$($Repository.name): cloned"
}
