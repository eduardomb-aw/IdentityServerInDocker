#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$false)]
    [string]$Mode = "prod",
    [Parameter(Mandatory=$false)]
    [string]$Tag = "latest",
    [Parameter(Mandatory=$false)]
    [switch]$Pull,
    [Parameter(Mandatory=$false)]
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 IdentityServer Docker Deployment Script" -ForegroundColor Green
Write-Host "Mode: $Mode | Tag: $Tag" -ForegroundColor Yellow

# Configuration
$images = @{
    "identityserver" = "ghcr.io/eduardomb-aw/identityserverindocker-identityserver"
    "adminui" = "ghcr.io/eduardomb-aw/identityserverindocker-adminui"
}

$composeFile = if ($Mode -eq "prod") { "docker-compose.prod.yml" } else { "docker-compose.yml" }

# Functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n📋 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-DockerCompose {
    try {
        $null = docker-compose --version
        return $true
    }
    catch {
        Write-Error "Docker Compose is not installed or not in PATH"
        return $false
    }
}

function Stop-Services {
    Write-Step "Stopping existing services..."
    try {
        docker-compose -f $composeFile down -v --remove-orphans
        Write-Success "Services stopped successfully"
    }
    catch {
        Write-Host "⚠️ No services to stop or error occurred" -ForegroundColor Yellow
    }
}

function Get-Images {
    Write-Step "Pulling latest images..."
    foreach ($service in $images.Keys) {
        $imageWithTag = "$($images[$service]):$Tag"
        Write-Host "Pulling $imageWithTag..." -ForegroundColor Yellow
        try {
            docker pull $imageWithTag
            Write-Success "Pulled $imageWithTag"
        }
        catch {
            Write-Error "Failed to pull $imageWithTag"
            throw
        }
    }
}

function Start-Services {
    Write-Step "Starting services with $composeFile..."
    try {
        docker-compose -f $composeFile up -d
        Write-Success "Services started successfully"
    }
    catch {
        Write-Error "Failed to start services"
        throw
    }
}

function Wait-ForServices {
    Write-Step "Waiting for services to be healthy..."
    
    $services = @(
        @{ Name = "IdentityServer"; Url = "https://localhost:5001/health"; Container = "identityserver-main" }
        @{ Name = "AdminUI"; Url = "https://localhost:5003/health"; Container = "identityserver-adminui" }
    )
    
    foreach ($service in $services) {
        Write-Host "Waiting for $($service.Name)..." -ForegroundColor Yellow
        $maxAttempts = 30
        $attempt = 0
        $healthy = $false
        
        while ($attempt -lt $maxAttempts -and -not $healthy) {
            try {
                $response = Invoke-WebRequest -Uri $service.Url -Method GET -SkipCertificateCheck -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    $healthy = $true
                    Write-Success "$($service.Name) is healthy"
                }
            }
            catch {
                $attempt++
                if ($attempt -eq $maxAttempts) {
                    Write-Error "$($service.Name) failed to become healthy after $maxAttempts attempts"
                    # Show container logs for debugging
                    Write-Host "Container logs for $($service.Container):" -ForegroundColor Yellow
                    docker logs $service.Container --tail 20
                    throw
                }
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Show-Status {
    Write-Step "Service Status"
    docker-compose -f $composeFile ps
    
    Write-Step "Service URLs"
    Write-Host "🔐 IdentityServer: https://localhost:5001" -ForegroundColor Green
    Write-Host "🎛️  AdminUI: https://localhost:5003" -ForegroundColor Green
    Write-Host "🔍 Health Checks:" -ForegroundColor Yellow
    Write-Host "   - IdentityServer: https://localhost:5001/health" -ForegroundColor Gray
    Write-Host "   - AdminUI: https://localhost:5003/health" -ForegroundColor Gray
}

function Clear-Resources {
    Write-Step "Cleaning up Docker resources..."
    
    # Stop all containers
    Stop-Services
    
    # Remove unused images
    Write-Host "Removing unused images..." -ForegroundColor Yellow
    docker image prune -f
    
    # Remove unused volumes
    Write-Host "Removing unused volumes..." -ForegroundColor Yellow  
    docker volume prune -f
    
    # Remove unused networks
    Write-Host "Removing unused networks..." -ForegroundColor Yellow
    docker network prune -f
    
    Write-Success "Cleanup completed"
}

# Main execution
try {
    if (-not (Test-DockerCompose)) {
        exit 1
    }

    if ($Clean) {
        Clear-Resources
        exit 0
    }

    # Stop existing services
    Stop-Services

    # Pull images if requested or in prod mode
    if ($Pull -or $Mode -eq "prod") {
        Get-Images
    }

    # Start services
    Start-Services

    # Wait for health checks
    Wait-ForServices

    # Show status
    Show-Status

    Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host "Services are running and healthy." -ForegroundColor Green
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "- Check Docker daemon is running" -ForegroundColor Gray
    Write-Host "- Verify network connectivity to ghcr.io" -ForegroundColor Gray
    Write-Host "- Check container logs: docker-compose -f $composeFile logs" -ForegroundColor Gray
    exit 1
}