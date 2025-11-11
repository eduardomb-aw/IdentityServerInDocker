# Stop all services and clean up
Write-Host "Stopping Identity Server services..." -ForegroundColor Yellow

docker-compose down --remove-orphans

Write-Host "Services stopped." -ForegroundColor Green

# Optionally remove volumes (uncomment if you want to reset databases)
# Write-Host "Removing volumes..." -ForegroundColor Yellow
# docker-compose down -v

Write-Host "`nTo completely reset (including database data):" -ForegroundColor Cyan
Write-Host "docker-compose down -v" -ForegroundColor White