[CmdletBinding()]
param(
    [string]$BackendDirectory
)

$ErrorActionPreference = "Stop"
$RepositoryRoot = Split-Path -Parent $PSScriptRoot
if (-not $BackendDirectory) {
    $BackendDirectory = Join-Path (Split-Path -Parent $RepositoryRoot) "TSP-backend"
}
$BackendDirectory = (Resolve-Path $BackendDirectory).Path
$QaDirectory = Join-Path $RepositoryRoot ".tmp\qa"
$Address = "127.0.0.1:3100"
$BaseUrl = "http://$Address"

New-Item -ItemType Directory -Force $QaDirectory | Out-Null
& rustup run 1.98.1 cargo build --locked --manifest-path (Join-Path $BackendDirectory "Cargo.toml")
if ($LASTEXITCODE -ne 0) {
    throw "TSP-backend build failed."
}

$Binary = Join-Path $BackendDirectory "target\debug\tsp-backend.exe"
$StdoutLog = Join-Path $QaDirectory "backend.stdout.log"
$StderrLog = Join-Path $QaDirectory "backend.stderr.log"
$PreviousBindAddress = $env:TSP_BIND_ADDRESS
$PreviousLogFormat = $env:TSP_LOG_FORMAT
$BackendProcess = $null

try {
    $env:TSP_BIND_ADDRESS = $Address
    $env:TSP_LOG_FORMAT = "human"
    $BackendProcess = Start-Process `
        -FilePath $Binary `
        -WorkingDirectory $BackendDirectory `
        -RedirectStandardOutput $StdoutLog `
        -RedirectStandardError $StderrLog `
        -WindowStyle Hidden `
        -PassThru

    $Health = $null
    for ($Attempt = 0; $Attempt -lt 30; $Attempt++) {
        if ($BackendProcess.HasExited) {
            throw "Backend exited before becoming ready. See $StderrLog"
        }
        try {
            $Health = Invoke-RestMethod "$BaseUrl/api/v1/health/ready"
            break
        }
        catch {
            Start-Sleep -Seconds 1
        }
    }

    if (-not $Health) {
        throw "Backend did not become ready within 30 seconds. See $StderrLog"
    }
    if ($Health.service -ne "tsp-backend" -or $Health.status -ne "ok" -or -not $Health.version) {
        throw "Backend readiness response does not match the public contract."
    }

    $Echo = Invoke-RestMethod `
        -Method Post `
        -Uri "$BaseUrl/api/v1/echo" `
        -ContentType "application/json" `
        -Body '{"message":"platform-integration"}'
    if ($Echo.message -ne "platform-integration") {
        throw "Backend echo response does not match the public contract."
    }

    Write-Host "TSP-backend readiness and echo contracts passed."
}
finally {
    if ($BackendProcess -and -not $BackendProcess.HasExited) {
        Stop-Process -Id $BackendProcess.Id
        $BackendProcess.WaitForExit()
    }
    $env:TSP_BIND_ADDRESS = $PreviousBindAddress
    $env:TSP_LOG_FORMAT = $PreviousLogFormat
}
