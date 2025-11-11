# Start Identity Server and AdminUI locally for development
Write-Host "Starting Identity Server applications locally..." -ForegroundColor Green

# Create data directory if it doesn't exist
if (!(Test-Path ".\data")) {
    New-Item -ItemType Directory -Path ".\data"
    Write-Host "Created data directory" -ForegroundColor Yellow
}

# Function to start a .NET application in a new PowerShell window
function Start-DotNetApp {
    param(
        [string]$ProjectPath,
        [string]$AppName,
        [string]$Urls
    )
    
    $command = "cd '$PWD'; `$env:ASPNETCORE_URLS='$Urls'; dotnet run --project '$ProjectPath'; Read-Host 'Press Enter to close'"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $command -WindowStyle Normal
    Write-Host "Started $AppName at $Urls" -ForegroundColor Green
}

Write-Host "Starting applications..." -ForegroundColor Yellow

# Start Identity Server
Start-DotNetApp -ProjectPath "src\IdentityServer\IdentityServer.csproj" -AppName "Identity Server" -Urls "https://localhost:5001;http://localhost:5000"

# Wait a bit for Identity Server to start
Start-Sleep -Seconds 3

# Start Admin UI
Start-DotNetApp -ProjectPath "src\AdminUI\AdminUI.csproj" -AppName "Admin UI" -Urls "https://localhost:5003;http://localhost:5002"

Write-Host "`nApplications are starting..." -ForegroundColor Green
Write-Host "`nService URLs:" -ForegroundColor Cyan
Write-Host "- Identity Server: https://localhost:5001" -ForegroundColor White
Write-Host "- Admin UI: https://localhost:5003" -ForegroundColor White

Write-Host "`nNote: It may take a minute for both applications to fully start." -ForegroundColor Yellow
Write-Host "The first time you run this, the database will be created and seeded with sample data." -ForegroundColor Yellow

Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")