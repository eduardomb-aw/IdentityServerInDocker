#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Runs end-to-end tests for the IdentityServer + AdminUI Docker setup using Playwright
.DESCRIPTION
    This script sets up and runs comprehensive Playwright tests that verify:
    - AdminUI dashboard functionality
    - IdentityServer welcome page
    - Discovery endpoint validation
    - Cross-navigation between services
    - Known issues documentation
.PARAMETER TestName
    Optional: Run specific test by name pattern
.PARAMETER Headed
    Run tests in headed mode (visible browser)
.PARAMETER Debug
    Run tests in debug mode with step-by-step execution
.PARAMETER UI
    Open Playwright UI mode for interactive testing
.PARAMETER Install
    Install Playwright dependencies
.EXAMPLE
    .\Run-PlaywrightTests.ps1
    .\Run-PlaywrightTests.ps1 -Headed
    .\Run-PlaywrightTests.ps1 -TestName "AdminUI Dashboard"
    .\Run-PlaywrightTests.ps1 -Install
#>

param(
    [string]$TestName = "",
    [switch]$Headed = $false,
    [switch]$Debug = $false,
    [switch]$UI = $false,
    [switch]$Install = $false
)

$ErrorActionPreference = "Stop"

# Colors for output
$Green = [System.ConsoleColor]::Green
$Yellow = [System.ConsoleColor]::Yellow
$Red = [System.ConsoleColor]::Red
$Blue = [System.ConsoleColor]::Blue

function Write-ColoredOutput {
    param($Message, $Color = [System.ConsoleColor]::White)
    Write-Host $Message -ForegroundColor $Color
}

# Get script directory and navigate to tests folder
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TestsDir = Join-Path $ScriptDir "tests"
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-ColoredOutput "🎭 IdentityServer + AdminUI Playwright Tests" $Blue
Write-ColoredOutput "Project Root: $ProjectRoot" $Yellow
Write-ColoredOutput "Tests Directory: $TestsDir" $Yellow

# Check if tests directory exists
if (-not (Test-Path $TestsDir)) {
    Write-ColoredOutput "❌ Tests directory not found: $TestsDir" $Red
    Write-ColoredOutput "Creating tests directory..." $Yellow
    New-Item -ItemType Directory -Path $TestsDir -Force | Out-Null
}

# Navigate to tests directory
Set-Location $TestsDir

# Install Playwright if requested
if ($Install) {
    Write-ColoredOutput "📦 Installing Playwright dependencies..." $Blue
    
    if (-not (Test-Path "package.json")) {
        Write-ColoredOutput "❌ package.json not found in tests directory" $Red
        exit 1
    }
    
    Write-ColoredOutput "Installing npm packages..." $Yellow
    npm install
    
    Write-ColoredOutput "Installing Playwright browsers..." $Yellow
    npx playwright install
    
    Write-ColoredOutput "✅ Playwright installation complete!" $Green
    return
}

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-ColoredOutput "❌ node_modules not found. Please run with -Install first" $Red
    Write-ColoredOutput "Example: .\Run-PlaywrightTests.ps1 -Install" $Yellow
    exit 1
}

# Check if Docker containers are running
Write-ColoredOutput "🐳 Checking Docker containers..." $Blue

$identityServerRunning = docker ps --filter "name=identityserver" --filter "status=running" --format "table {{.Names}}" | Select-String "identityserver"
$adminUIRunning = docker ps --filter "name=adminui" --filter "status=running" --format "table {{.Names}}" | Select-String "adminui"

if (-not $identityServerRunning) {
    Write-ColoredOutput "❌ IdentityServer container is not running" $Red
    Write-ColoredOutput "Please start containers with: docker-compose up -d" $Yellow
    exit 1
}

if (-not $adminUIRunning) {
    Write-ColoredOutput "❌ AdminUI container is not running" $Red
    Write-ColoredOutput "Please start containers with: docker-compose up -d" $Yellow
    exit 1
}

Write-ColoredOutput "✅ Docker containers are running" $Green

# Test connectivity
Write-ColoredOutput "🔗 Testing service connectivity..." $Blue

try {
    $identityServerResponse = Invoke-WebRequest -Uri "https://localhost:5001" -SkipCertificateCheck -TimeoutSec 10
    Write-ColoredOutput "✅ IdentityServer is accessible (Status: $($identityServerResponse.StatusCode))" $Green
} catch {
    Write-ColoredOutput "❌ IdentityServer is not accessible: $_" $Red
    exit 1
}

try {
    $adminUIResponse = Invoke-WebRequest -Uri "https://localhost:5003" -SkipCertificateCheck -TimeoutSec 10
    Write-ColoredOutput "✅ AdminUI is accessible (Status: $($adminUIResponse.StatusCode))" $Green
} catch {
    Write-ColoredOutput "❌ AdminUI is not accessible: $_" $Red
    exit 1
}

# Build Playwright command
$playwrightCmd = "npx playwright test"

if ($TestName) {
    $playwrightCmd += " --grep `"$TestName`""
}

if ($Headed) {
    $playwrightCmd += " --headed"
}

if ($Debug) {
    $playwrightCmd += " --debug"
}

if ($UI) {
    $playwrightCmd += " --ui"
}

# Run tests
Write-ColoredOutput "🚀 Running Playwright tests..." $Blue
Write-ColoredOutput "Command: $playwrightCmd" $Yellow
Write-ColoredOutput "" 

try {
    Invoke-Expression $playwrightCmd
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-ColoredOutput "✅ All tests passed!" $Green
    } else {
        Write-ColoredOutput "❌ Some tests failed (Exit code: $exitCode)" $Red
    }
    
    # Show report location
    $reportPath = Join-Path $TestsDir "playwright-report"
    if (Test-Path $reportPath) {
        Write-ColoredOutput "📊 Test report available at: $reportPath" $Blue
        Write-ColoredOutput "View report: npx playwright show-report" $Yellow
    }
    
} catch {
    Write-ColoredOutput "❌ Failed to run tests: $_" $Red
    exit 1
}

# Return to original directory
Set-Location $ProjectRoot

Write-ColoredOutput "🎭 Playwright testing complete!" $Blue