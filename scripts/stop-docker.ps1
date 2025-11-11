#Requires -Version 5.1
<#
.SYNOPSIS
    Stops and cleans up IdentityServer Docker containers and resources

.DESCRIPTION
    This script stops the running containers, removes them, and optionally
    cleans up Docker images and volumes.

.PARAMETER RemoveImages
    Also remove the built Docker images

.PARAMETER RemoveVolumes
    Also remove Docker volumes (will delete data)

.PARAMETER Force
    Skip confirmation prompts

.EXAMPLE
    .\stop-docker.ps1
    
.EXAMPLE
    .\stop-docker.ps1 -RemoveImages -RemoveVolumes -Force
#>

param(
    [switch]$RemoveImages,
    [switch]$RemoveVolumes,
    [switch]$Force
)

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

Write-Host "IdentityServer4 Docker Cleanup" -ForegroundColor $Cyan
Write-Host "===============================" -ForegroundColor $Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -NoNewline
try {
    docker version --format '{{.Server.Version}}' 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅ Docker is running" -ForegroundColor $Green
    } else {
        Write-Host " ❌ Docker is not running" -ForegroundColor $Red
        Write-Host "Cannot cleanup containers without Docker running." -ForegroundColor $Yellow
        exit 1
    }
}
catch {
    Write-Host " ❌ Docker not found" -ForegroundColor $Red
    exit 1
}

# Check if docker-compose file exists
if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ docker-compose.yml not found in current directory" -ForegroundColor $Red
    Write-Host "Please run this script from the project root directory." -ForegroundColor $Yellow
    exit 1
}

# Stop and remove containers
Write-Host "🛑 Stopping containers..." -ForegroundColor $Yellow
try {
    docker-compose down
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Containers stopped and removed" -ForegroundColor $Green
    } else {
        Write-Host "⚠️ Some issues stopping containers (may not be running)" -ForegroundColor $Yellow
    }
}
catch {
    Write-Host "❌ Error stopping containers: $($_.Exception.Message)" -ForegroundColor $Red
}

# Remove images if requested
if ($RemoveImages) {
    if (-not $Force) {
        $response = Read-Host "Remove Docker images? This will require rebuilding next time (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Skipping image removal" -ForegroundColor $Yellow
            $RemoveImages = $false
        }
    }
    
    if ($RemoveImages) {
        Write-Host "🗑️ Removing Docker images..." -ForegroundColor $Yellow
        try {
            # Remove project images
            $images = docker images --filter "reference=identityserverindocker*" -q
            if ($images) {
                docker rmi $images --force
                Write-Host "✅ Project images removed" -ForegroundColor $Green
            } else {
                Write-Host "ℹ️ No project images found" -ForegroundColor $Yellow
            }
        }
        catch {
            Write-Host "❌ Error removing images: $($_.Exception.Message)" -ForegroundColor $Red
        }
    }
}

# Remove volumes if requested
if ($RemoveVolumes) {
    if (-not $Force) {
        $response = Read-Host "Remove Docker volumes? This will DELETE ALL DATA (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Skipping volume removal" -ForegroundColor $Yellow
            $RemoveVolumes = $false
        }
    }
    
    if ($RemoveVolumes) {
        Write-Host "🗑️ Removing Docker volumes..." -ForegroundColor $Yellow
        try {
            docker-compose down -v
            Write-Host "✅ Volumes removed" -ForegroundColor $Green
        }
        catch {
            Write-Host "❌ Error removing volumes: $($_.Exception.Message)" -ForegroundColor $Red
        }
    }
}

# Show remaining containers and images
Write-Host ""
Write-Host "📊 Current Docker status:" -ForegroundColor $Cyan

Write-Host "Containers:" -ForegroundColor $Yellow
$containers = docker ps -a --filter "name=identityserver" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
if ($containers) {
    Write-Host $containers
} else {
    Write-Host "No IdentityServer containers found" -ForegroundColor $Green
}

Write-Host ""
Write-Host "Images:" -ForegroundColor $Yellow
$images = docker images --filter "reference=identityserverindocker*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
if ($images) {
    Write-Host $images
} else {
    Write-Host "No IdentityServer images found" -ForegroundColor $Green
}

Write-Host ""
Write-Host "✅ Cleanup completed!" -ForegroundColor $Green
Write-Host ""
Write-Host "💡 Next steps:" -ForegroundColor $Yellow
Write-Host "   • Run .\scripts\start-docker.ps1 to start fresh containers"
Write-Host "   • Run .\scripts\start-identityserver.ps1 for local development"
Write-Host "   • Use -Build flag if you made code changes"