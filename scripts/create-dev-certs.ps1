# PowerShell script to create development certificates for HTTPS
Write-Host "Creating development certificates for Identity Server in Docker..." -ForegroundColor Green

# Create certs directory if it doesn't exist
$certsPath = ".\certs"
if (!(Test-Path $certsPath)) {
    New-Item -ItemType Directory -Path $certsPath
}

# Generate Identity Server certificate
Write-Host "Generating Identity Server certificate..." -ForegroundColor Yellow
dotnet dev-certs https -ep "$certsPath\identityserver.pfx" -p password --trust

# Generate Admin UI certificate
Write-Host "Generating Admin UI certificate..." -ForegroundColor Yellow
dotnet dev-certs https -ep "$certsPath\adminui.pfx" -p password

Write-Host "Certificates created successfully!" -ForegroundColor Green
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "- $certsPath\identityserver.pfx" -ForegroundColor White
Write-Host "- $certsPath\adminui.pfx" -ForegroundColor White

Write-Host "`nIMPORTANT: These certificates are for development only!" -ForegroundColor Red
Write-Host "Password for certificates: password" -ForegroundColor Yellow