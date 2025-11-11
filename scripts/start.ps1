# Build and run all services
Write-Host "Starting Identity Server infrastructure..." -ForegroundColor Green

# Check if Docker is running
try {
    docker version | Out-Null
    Write-Host "Docker is running ✓" -ForegroundColor Green
} catch {
    Write-Host "Error: Docker is not running or not installed!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}

# Create certificates if they don't exist
if (!(Test-Path ".\certs\identityserver.pfx") -or !(Test-Path ".\certs\adminui.pfx")) {
    Write-Host "Creating development certificates..." -ForegroundColor Yellow
    .\scripts\create-dev-certs.ps1
}

# Create logs directories
Write-Host "Creating log directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path ".\logs\identityserver" -Force | Out-Null
New-Item -ItemType Directory -Path ".\logs\adminui" -Force | Out-Null

# Build and start services
Write-Host "Building and starting services..." -ForegroundColor Yellow
docker-compose down --remove-orphans
docker-compose up --build -d

Write-Host "`nServices starting..." -ForegroundColor Green
Write-Host "This may take a few minutes on first run while databases are initialized." -ForegroundColor Yellow

Write-Host "`nService URLs:" -ForegroundColor Cyan
Write-Host "- Identity Server: https://localhost:5001" -ForegroundColor White
Write-Host "- Admin UI: https://localhost:5003" -ForegroundColor White
Write-Host "- SQL Server: localhost:1433" -ForegroundColor White

Write-Host "`nTo view logs:" -ForegroundColor Cyan
Write-Host "docker-compose logs -f" -ForegroundColor White

Write-Host "`nTo stop services:" -ForegroundColor Cyan
Write-Host "docker-compose down" -ForegroundColor White