#Requires -Version 5.1
<#
.SYNOPSIS
    Starts the IdentityServer and AdminUI using Docker Compose

.DESCRIPTION
    This script builds and starts the IdentityServer4 container and AdminUI placeholder
    using Docker Compose. It includes basic validation and helpful output.

.PARAMETER Build
    Force rebuild of Docker images

.PARAMETER Detach
    Run containers in detached mode (background)

.EXAMPLE
    .\start-docker.ps1
    
.EXAMPLE
    .\start-docker.ps1 -Build -Detach
#>

param(
    [switch]$Build,
    [switch]$Detach
)

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"  
$Cyan = "Cyan"

Write-Host "IdentityServer4 Docker Startup" -ForegroundColor $Cyan
Write-Host "==============================" -ForegroundColor $Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -NoNewline
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅ Docker is running (v$dockerVersion)" -ForegroundColor $Green
    } else {
        Write-Host " ❌ Docker is not running" -ForegroundColor $Red
        Write-Host "Please start Docker Desktop and try again." -ForegroundColor $Yellow
        exit 1
    }
}
catch {
    Write-Host " ❌ Docker not found" -ForegroundColor $Red
    Write-Host "Please install Docker Desktop and try again." -ForegroundColor $Yellow
    exit 1
}

# Check if docker-compose file exists
if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ docker-compose.yml not found in current directory" -ForegroundColor $Red
    Write-Host "Please run this script from the project root directory." -ForegroundColor $Yellow
    exit 1
}

# Build arguments
$composeArgs = @("up")

if ($Build) {
    Write-Host "🔨 Force rebuilding Docker images..." -ForegroundColor $Yellow
    $composeArgs += "--build"
}

if ($Detach) {
    $composeArgs += "-d"
    Write-Host "🚀 Starting containers in background..." -ForegroundColor $Yellow
} else {
    Write-Host "🚀 Starting containers (Ctrl+C to stop)..." -ForegroundColor $Yellow
}

Write-Host ""

# Start containers
try {
    & docker-compose @composeArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Containers started successfully!" -ForegroundColor $Green
        Write-Host ""
        Write-Host "🔗 Services are available at:" -ForegroundColor $Cyan
        Write-Host "   IdentityServer (HTTP):  http://localhost:5000" -ForegroundColor $Green
        Write-Host "   IdentityServer (HTTPS): https://localhost:5001" -ForegroundColor $Green  
        Write-Host "   Admin UI:               http://localhost:8080" -ForegroundColor $Green
        Write-Host ""
        Write-Host "🧪 Test the services:" -ForegroundColor $Yellow
        Write-Host "   .\scripts\test-endpoints.ps1" -ForegroundColor $Yellow
        Write-Host "   .\scripts\test-auth-flows.ps1" -ForegroundColor $Yellow
        Write-Host ""
        
        if ($Detach) {
            Write-Host "📊 Monitor containers:" -ForegroundColor $Yellow
            Write-Host "   docker-compose logs -f" -ForegroundColor $Yellow
            Write-Host "   docker-compose ps" -ForegroundColor $Yellow
            Write-Host ""
            Write-Host "⏹️  Stop containers:" -ForegroundColor $Yellow
            Write-Host "   docker-compose down" -ForegroundColor $Yellow
        } else {
            Write-Host "⏹️  Press Ctrl+C to stop containers" -ForegroundColor $Yellow
        }
    } else {
        Write-Host "❌ Failed to start containers" -ForegroundColor $Red
        Write-Host "Check the logs above for error details." -ForegroundColor $Yellow
        exit 1
    }
}
catch {
    Write-Host "❌ Error starting containers: $($_.Exception.Message)" -ForegroundColor $Red
    exit 1
}