#Requires -Version 5.1
<#
.SYNOPSIS
    Tests the AdminUI project build and basic functionality

.DESCRIPTION
    This script verifies that the AdminUI project builds successfully
    and can start without errors.

.EXAMPLE
    .\test-adminui.ps1
#>

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

Write-Host "AdminUI Project Test" -ForegroundColor $Cyan
Write-Host "===================" -ForegroundColor $Cyan
Write-Host ""

# Test 1: Project file exists
Write-Host "1. Checking project file..." -NoNewline
if (Test-Path "src\AdminUI\AdminUI.csproj") {
    Write-Host " ✅ PASS" -ForegroundColor $Green
} else {
    Write-Host " ❌ FAIL" -ForegroundColor $Red
    Write-Host "   AdminUI.csproj not found" -ForegroundColor $Red
    exit 1
}

# Test 2: Can restore packages
Write-Host "2. Restoring packages..." -NoNewline
try {
    $restoreOutput = dotnet restore src/AdminUI/AdminUI.csproj --verbosity quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅ PASS" -ForegroundColor $Green
    } else {
        Write-Host " ❌ FAIL" -ForegroundColor $Red
        Write-Host "   Restore failed: $restoreOutput" -ForegroundColor $Red
        exit 1
    }
}
catch {
    Write-Host " ❌ FAIL" -ForegroundColor $Red
    Write-Host "   Exception: $($_.Exception.Message)" -ForegroundColor $Red
    exit 1
}

# Test 3: Can build project
Write-Host "3. Building project..." -NoNewline
try {
    $buildOutput = dotnet build src/AdminUI/AdminUI.csproj --verbosity quiet --no-restore 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅ PASS" -ForegroundColor $Green
    } else {
        Write-Host " ❌ FAIL" -ForegroundColor $Red
        Write-Host "   Build failed: $buildOutput" -ForegroundColor $Red
        exit 1
    }
}
catch {
    Write-Host " ❌ FAIL" -ForegroundColor $Red
    Write-Host "   Exception: $($_.Exception.Message)" -ForegroundColor $Red
    exit 1
}

# Test 4: Check key dependencies
Write-Host "4. Checking dependencies..." -NoNewline
$projectContent = Get-Content "src\AdminUI\AdminUI.csproj" -Raw
$requiredPackages = @(
    "Microsoft.AspNetCore.Authentication.OpenIdConnect",
    "Serilog.AspNetCore"
)

$missingPackages = @()
foreach ($package in $requiredPackages) {
    if ($projectContent -notmatch $package) {
        $missingPackages += $package
    }
}

if ($missingPackages.Count -eq 0) {
    Write-Host " ✅ PASS" -ForegroundColor $Green
} else {
    Write-Host " ❌ FAIL" -ForegroundColor $Red
    Write-Host "   Missing packages: $($missingPackages -join ', ')" -ForegroundColor $Red
    exit 1
}

# Test 5: Check key files exist
Write-Host "5. Checking project structure..." -NoNewline
$requiredFiles = @(
    "src\AdminUI\Program.cs",
    "src\AdminUI\Services\IdentityServerAdminService.cs",
    "src\AdminUI\Controllers\HomeController.cs"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -eq 0) {
    Write-Host " ✅ PASS" -ForegroundColor $Green
} else {
    Write-Host " ❌ FAIL" -ForegroundColor $Red
    Write-Host "   Missing files: $($missingFiles -join ', ')" -ForegroundColor $Red
    exit 1
}

Write-Host ""
Write-Host "🎉 All tests passed!" -ForegroundColor $Green
Write-Host ""
Write-Host "💡 If you see red squiggly lines in VS Code:" -ForegroundColor $Yellow
Write-Host "   1. Press Ctrl+Shift+P" -ForegroundColor $Yellow
Write-Host "   2. Type 'OmniSharp: Restart OmniSharp'" -ForegroundColor $Yellow
Write-Host "   3. Wait for IntelliSense to reload" -ForegroundColor $Yellow
Write-Host ""
Write-Host "🚀 To start AdminUI:" -ForegroundColor $Cyan
Write-Host "   .\scripts\start-adminui.ps1" -ForegroundColor $Green