#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Quick setup script to configure User Secrets for development testing.

.DESCRIPTION
    This script provides a quick way to set up a development client secret
    for testing the Document Management OAuth 2.0 integration without
    needing to remember the full User Secrets command syntax.

.PARAMETER DemoSecret
    Use a demo secret for testing purposes

.EXAMPLE
    .\scripts\setup-dev-secret.ps1
    Prompts for a client secret
    
.EXAMPLE
    .\scripts\setup-dev-secret.ps1 -DemoSecret
    Uses a demo secret for quick testing
#>

param(
    [Parameter(HelpMessage = "Use a demo secret for testing")]
    [switch]$DemoSecret
)

Write-Host "🚀 Quick User Secrets Setup for Development" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

if ($DemoSecret) {
    Write-Host "🔧 Setting up demo secret for testing..." -ForegroundColor Yellow
    & ".\scripts\manage-user-secrets.ps1" -Action Set -Secret (ConvertTo-SecureString "demo-secret-12345-for-testing-only" -AsPlainText -Force)
} else {
    Write-Host "🔑 Please provide your Document Management client secret..." -ForegroundColor Yellow
    & ".\scripts\manage-user-secrets.ps1" -Action Set
}

Write-Host ""
Write-Host "✨ Setup complete! Next steps:" -ForegroundColor Green
Write-Host "   1. Restart IdentityServer: docker-compose restart identityserver" -ForegroundColor White
Write-Host "   2. Test the setup: .\scripts\test-doc-mgmt-client.ps1 -SkipCertificateCheck" -ForegroundColor White
Write-Host "   3. Try the demo: .\scripts\demo-doc-mgmt-oauth.ps1 -Interactive" -ForegroundColor White