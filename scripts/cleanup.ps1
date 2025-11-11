#Requires -Version 5.1
<#
.SYNOPSIS
    Cleans up temporary files and build artifacts from the IdentityServer project

.DESCRIPTION
    This script removes build artifacts, temporary files, and other unnecessary 
    files from the IdentityServer4 project to keep it clean.

.PARAMETER Deep
    Perform a deep clean including NuGet cache and global temp files

.EXAMPLE
    .\cleanup.ps1
    
.EXAMPLE
    .\cleanup.ps1 -Deep
#>

param(
    [switch]$Deep
)

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"

Write-Host "IdentityServer4 Project Cleanup" -ForegroundColor $Cyan
Write-Host "===============================" -ForegroundColor $Cyan
Write-Host ""

$itemsRemoved = 0

# Function to remove items safely
function Remove-ItemSafely {
    param($Path, $Description)
    
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Host "✅ Removed: $Description" -ForegroundColor $Green
            return 1
        }
        catch {
            Write-Host "⚠️  Could not remove: $Description - $($_.Exception.Message)" -ForegroundColor $Yellow
            return 0
        }
    }
    else {
        Write-Host "ℹ️  Not found: $Description" -ForegroundColor $Yellow
        return 0
    }
}

# Stop any running dotnet processes
Write-Host "🛑 Stopping dotnet processes..." -ForegroundColor $Yellow
try {
    Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "✅ Stopped dotnet processes" -ForegroundColor $Green
}
catch {
    Write-Host "ℹ️  No dotnet processes to stop" -ForegroundColor $Yellow
}

# Remove build artifacts
Write-Host ""
Write-Host "🧹 Cleaning build artifacts..." -ForegroundColor $Yellow

$itemsRemoved += Remove-ItemSafely "src\IdentityServer\bin" "Build output (bin)"
$itemsRemoved += Remove-ItemSafely "src\IdentityServer\obj" "Build cache (obj)"

# Remove backup files
Write-Host ""
Write-Host "🧹 Cleaning backup files..." -ForegroundColor $Yellow

$backupFiles = Get-ChildItem -Recurse -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match '\.(bak|backup|tmp|orig|swp|swo|~)$|^\.#|#.*#$' }

foreach ($file in $backupFiles) {
    $itemsRemoved += Remove-ItemSafely $file.FullName "Backup file: $($file.Name)"
}

# Remove log files (optional)
Write-Host ""
$response = Read-Host "Remove log files? (y/N)"
if ($response -eq 'y' -or $response -eq 'Y') {
    $itemsRemoved += Remove-ItemSafely "logs" "Log files"
    $itemsRemoved += Remove-ItemSafely "src\IdentityServer\logs" "IdentityServer log files"
}

# Remove unnecessary folders (if they exist)
Write-Host ""
Write-Host "🧹 Cleaning unnecessary folders..." -ForegroundColor $Yellow

$itemsRemoved += Remove-ItemSafely "database" "Database folder (not needed for in-memory)"
$itemsRemoved += Remove-ItemSafely "data" "Data folder (not needed for in-memory)"

# Deep clean (optional)
if ($Deep) {
    Write-Host ""
    Write-Host "🔥 Performing deep clean..." -ForegroundColor $Yellow
    
    # Clean dotnet cache
    try {
        dotnet nuget locals all --clear | Out-Null
        Write-Host "✅ Cleared NuGet cache" -ForegroundColor $Green
        $itemsRemoved++
    }
    catch {
        Write-Host "⚠️  Could not clear NuGet cache" -ForegroundColor $Yellow
    }
    
    # Clean temp files
    $tempPath = $env:TEMP
    $tempFiles = Get-ChildItem -Path $tempPath -Filter "*identityserver*" -ErrorAction SilentlyContinue
    foreach ($file in $tempFiles) {
        $itemsRemoved += Remove-ItemSafely $file.FullName "Temp file: $($file.Name)"
    }
}

# Summary
Write-Host ""
Write-Host "📊 Cleanup Summary" -ForegroundColor $Cyan
Write-Host "==================" -ForegroundColor $Cyan

if ($itemsRemoved -gt 0) {
    Write-Host "✅ Removed $itemsRemoved items" -ForegroundColor $Green
} else {
    Write-Host "ℹ️  No items needed cleanup" -ForegroundColor $Yellow
}

Write-Host ""
Write-Host "💡 Next steps:" -ForegroundColor $Yellow
Write-Host "   • Run 'dotnet restore' to restore packages"
Write-Host "   • Run 'dotnet build' to verify everything compiles"
Write-Host "   • Use .\scripts\start-identityserver.ps1 to test"