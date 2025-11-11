# Start IdentityServer4 Development Environment
# This script starts the IdentityServer in development mode

Write-Host "🚀 Starting IdentityServer4..." -ForegroundColor Green
Write-Host ""

# Navigate to the IdentityServer directory
$IdentityServerPath = Join-Path $PSScriptRoot "..\src\IdentityServer"
Set-Location $IdentityServerPath

# Set development environment
$env:ASPNETCORE_ENVIRONMENT = "Development"

Write-Host "📍 Directory: $IdentityServerPath" -ForegroundColor Cyan
Write-Host "🌍 Environment: $env:ASPNETCORE_ENVIRONMENT" -ForegroundColor Cyan
Write-Host "🌐 URLs: http://localhost:5000, https://localhost:5001" -ForegroundColor Cyan
Write-Host ""

Write-Host "Starting server..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the server
dotnet run