#Requires -Version 5.1
<#
.SYNOPSIS
    Starts the AdminUI application in development mode

.DESCRIPTION
    This script sets up the development environment and starts the AdminUI
    application that provides a web interface for managing the IdentityServer4.

.EXAMPLE
    .\start-adminui.ps1
#>

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"

Write-Host "IdentityServer4 AdminUI Startup" -ForegroundColor $Cyan
Write-Host "===============================" -ForegroundColor $Cyan
Write-Host ""

# Set environment variables for development
$env:ASPNETCORE_ENVIRONMENT = "Development"
$env:ASPNETCORE_URLS = "http://localhost:5002;https://localhost:5003"

Write-Host "Environment Configuration:" -ForegroundColor $Yellow
Write-Host "  ASPNETCORE_ENVIRONMENT: $env:ASPNETCORE_ENVIRONMENT" -ForegroundColor $Green
Write-Host "  HTTP URL: http://localhost:5002" -ForegroundColor $Green
Write-Host "  HTTPS URL: https://localhost:5003" -ForegroundColor $Green
Write-Host ""

# Check if the project file exists
$projectPath = "src\AdminUI\AdminUI.csproj"
if (-not (Test-Path $projectPath)) {
    Write-Host "❌ Project file not found: $projectPath" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory." -ForegroundColor $Yellow
    exit 1
}

Write-Host "🚀 Starting AdminUI..." -ForegroundColor $Yellow
Write-Host ""

# Navigate to the AdminUI project directory and start the application
try {
    Set-Location "src\AdminUI"
    Write-Host "📍 Working directory: $(Get-Location)" -ForegroundColor $Yellow
    Write-Host ""
    
    Write-Host "🔧 Building project..." -ForegroundColor $Yellow
    dotnet build --verbosity quiet
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Build successful" -ForegroundColor $Green
        Write-Host ""
        Write-Host "🌐 AdminUI will be available at:" -ForegroundColor $Cyan
        Write-Host "   HTTP:  http://localhost:5002" -ForegroundColor $Green
        Write-Host "   HTTPS: https://localhost:5003" -ForegroundColor $Green
        Write-Host ""
        Write-Host "💡 Make sure IdentityServer is running on https://localhost:5001" -ForegroundColor $Yellow
        Write-Host "   Use .\scripts\start-identityserver.ps1 to start it" -ForegroundColor $Yellow
        Write-Host ""
        Write-Host "⏹️  Press Ctrl+C to stop the server" -ForegroundColor $Yellow
        Write-Host ""
        
        # Start the application
        dotnet run
    } else {
        Write-Host "❌ Build failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Error starting AdminUI: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    # Return to the original directory
    Set-Location "..\..\"
}