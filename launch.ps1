# Version identifier for the Grade Monitor launcher script
$VERSION = "2.8"

# Define the root directory of the application
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set working directory to project root for correct relative path resolution
Set-Location $projectDir

# Target URL for the dashboard frontend
$targetUrl = "http://localhost:3000/"
$healthEndpoint = "http://localhost:3000/api/default-config"

# Test whether the local Node.js proxy server is currently running and responding
function Test-ServerRunning {
    try {
        $response = Invoke-WebRequest -Uri $healthEndpoint -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop
        return ($response.StatusCode -eq 200)
    } catch {
        return $false
    }
}

# If the server is not currently running, launch node decoupled in the background using WMI
if (-not (Test-ServerRunning)) {
    Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
        CommandLine = "cmd /c node server.js >> server.log 2>&1"
        CurrentDirectory = $projectDir
    } | Out-Null

    # Poll the health endpoint until the server is ready to accept requests (max 10 seconds)
    $maxAttempts = 40
    $attempt = 0
    $isReady = $false

    while ($attempt -lt $maxAttempts -and -not $isReady) {
        Start-Sleep -Milliseconds 250
        $attempt++
        $isReady = Test-ServerRunning
    }
}

# Open the Canvas Grade Monitor dashboard in the user's default web browser
Start-Process $targetUrl
