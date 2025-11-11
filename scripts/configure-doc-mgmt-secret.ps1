#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Configures the Document Management client secret securely in IdentityServer.

.DESCRIPTION
    This script allows you to set the actual client secret for the Document Management client
    without hardcoding it in the repository. The secret can be provided via:
    - Command line parameter (secure string)
    - Environment variable (DOC_MGMT_CLIENT_SECRET)
    - Interactive prompt (secure input)

.PARAMETER ClientSecret
    The client secret to configure. If not provided, will prompt securely.

.PARAMETER EnvironmentVariable
    Use the DOC_MGMT_CLIENT_SECRET environment variable for the secret.

.EXAMPLE
    .\scripts\configure-doc-mgmt-secret.ps1
    Prompts for the client secret securely
    
.EXAMPLE
    .\scripts\configure-doc-mgmt-secret.ps1 -EnvironmentVariable
    Uses the DOC_MGMT_CLIENT_SECRET environment variable
    
.EXAMPLE
    $secret = Read-Host "Enter secret" -AsSecureString
    .\scripts\configure-doc-mgmt-secret.ps1 -ClientSecret $secret
#>

param(
    [Parameter(HelpMessage = "The client secret as a secure string")]
    [SecureString]$ClientSecret,
    
    [Parameter(HelpMessage = "Use the DOC_MGMT_CLIENT_SECRET environment variable")]
    [switch]$EnvironmentVariable
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🔐 Document Management Client Secret Configuration" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$programCsPath = Join-Path $rootDir "src\IdentityServer\Program.cs"

# Verify Program.cs exists
if (-not (Test-Path $programCsPath)) {
    Write-Error "❌ Program.cs not found at: $programCsPath"
    exit 1
}

# Get the client secret
$secretValue = $null

if ($EnvironmentVariable) {
    $secretValue = $env:DOC_MGMT_CLIENT_SECRET
    if ([string]::IsNullOrWhiteSpace($secretValue)) {
        Write-Error "❌ DOC_MGMT_CLIENT_SECRET environment variable is not set"
        exit 1
    }
    Write-Host "✅ Using client secret from environment variable" -ForegroundColor Green
}
elseif ($ClientSecret) {
    $secretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret))
    Write-Host "✅ Using provided secure client secret" -ForegroundColor Green
}
else {
    Write-Host "🔑 Please enter the Document Management client secret:" -ForegroundColor Yellow
    $secureInput = Read-Host "Client Secret" -AsSecureString
    $secretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput))
}

if ([string]::IsNullOrWhiteSpace($secretValue)) {
    Write-Error "❌ No client secret provided"
    exit 1
}

Write-Host ""
Write-Host "📝 Updating Program.cs with the client secret..." -ForegroundColor Yellow

# Read the current Program.cs content
$content = Get-Content $programCsPath -Raw

# Replace the placeholder with the actual secret
$content = $content -replace 'YOUR_CLIENT_SECRET_HERE', $secretValue

# Write the updated content back to the file
Set-Content $programCsPath $content -Encoding UTF8

Write-Host "✅ Client secret configured successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Restart IdentityServer to apply changes:" -ForegroundColor White
Write-Host "      docker-compose restart identityserver" -ForegroundColor Yellow
Write-Host ""
Write-Host "   2. Test the configuration:" -ForegroundColor White
Write-Host "      .\scripts\test-doc-mgmt-client.ps1 -SkipCertificateCheck" -ForegroundColor Yellow
Write-Host ""

# Security reminder
Write-Host "🔒 Security Reminder:" -ForegroundColor Red
Write-Host "   • The client secret is now stored in Program.cs" -ForegroundColor White
Write-Host "   • Make sure not to commit this file with the real secret" -ForegroundColor White
Write-Host "   • Consider using Azure Key Vault for production deployments" -ForegroundColor White
Write-Host ""

Write-Host "💡 To revert to placeholder:" -ForegroundColor Blue
Write-Host "   git checkout -- src/IdentityServer/Program.cs" -ForegroundColor Yellow

Write-Host ""
Write-Host "✨ Configuration completed!" -ForegroundColor Green