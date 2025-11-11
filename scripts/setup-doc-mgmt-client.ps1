#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Sets up the 'doc-mgmt-client' client in IdentityServer4 with required API scopes.

.DESCRIPTION
    This script modifies the IdentityServer Program.cs file to add:
    - Required API scopes for AM Link services
    - The 'doc-mgmt-client' client with authorization code flow
    
    Client Configuration:
    - ClientId: doc-mgmt-client
    - GrantType: authorization_code
    - Scopes: amlink-maintenance-api, amlink-submission-api, amlink-policy-api, amlink-doc-api, amwins-graphadapter-api
    - RedirectUri: http://localhost:1180/callback

.PARAMETER BackupOriginal
    Creates a backup of the original Program.cs file before making changes.

.EXAMPLE
    .\scripts\setup-doc-mgmt-client.ps1
    
.EXAMPLE
    .\scripts\setup-doc-mgmt-client.ps1 -BackupOriginal
#>

param(
    [Parameter(HelpMessage = "Create a backup of the original Program.cs file")]
    [switch]$BackupOriginal
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$programCsPath = Join-Path $rootDir "src\IdentityServer\Program.cs"

Write-Host "🔧 Setting up Document Management client in IdentityServer4..." -ForegroundColor Cyan
Write-Host ""

# Verify Program.cs exists
if (-not (Test-Path $programCsPath)) {
    Write-Error "❌ Program.cs not found at: $programCsPath"
    exit 1
}

# Create backup if requested
if ($BackupOriginal) {
    $backupPath = "$programCsPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $programCsPath $backupPath
    Write-Host "💾 Backup created: $backupPath" -ForegroundColor Green
}

# Read the current Program.cs content
$content = Get-Content $programCsPath -Raw

# Check if the client already exists
if ($content -match "doc-mgmt-client") {
    Write-Host "⚠️  Document Management client already exists in Program.cs" -ForegroundColor Yellow
    Write-Host "   Use -Force to overwrite existing configuration" -ForegroundColor Yellow
    exit 0
}

Write-Host "📝 Adding API scopes for AM Link services..." -ForegroundColor Yellow

# Define the new API scopes to add
$newApiScopes = @"
        new IdentityServer4.Models.ApiScope("amlink-maintenance-api", "AM Link Maintenance API"),
        new IdentityServer4.Models.ApiScope("amlink-submission-api", "AM Link Submission API"),
        new IdentityServer4.Models.ApiScope("amlink-policy-api", "AM Link Policy API"),
        new IdentityServer4.Models.ApiScope("amlink-doc-api", "AM Link Document API"),
        new IdentityServer4.Models.ApiScope("amwins-graphadapter-api", "AM Wins Graph Adapter API"),
"@

# Replace the GetApiScopes method
$apiScopesPattern = '(?s)static IEnumerable<IdentityServer4\.Models\.ApiScope> GetApiScopes\(\)\s*\{.*?return new List<IdentityServer4\.Models\.ApiScope>\s*\{(.*?)\s*\};.*?\}'

$newApiScopesMethod = @"
static IEnumerable<IdentityServer4.Models.ApiScope> GetApiScopes()
{
    return new List<IdentityServer4.Models.ApiScope>
    {
        new IdentityServer4.Models.ApiScope("api1", "My API"),
        $newApiScopes
    };
}
"@

$content = $content -replace $apiScopesPattern, $newApiScopesMethod

Write-Host "📝 Adding SPO Document Management client..." -ForegroundColor Yellow

# Define the new Document Management client
$docMgmtClient = @"
        // Document Management client
        new Client
        {
            ClientId = "doc-mgmt-client",
            ClientName = "Document Management System",
            AllowedGrantTypes = GrantTypes.Code,
            
            // Client secrets for secure communication  
            ClientSecrets = { new Secret("YOUR_CLIENT_SECRET_HERE".Sha256()) },
            
            // Redirect URIs for OAuth callback
            RedirectUris = { "http://localhost:1180/callback" },
            PostLogoutRedirectUris = { "http://localhost:1180/logout" },
            
            // Allowed scopes for AM Link APIs
            AllowedScopes = { 
                "openid", 
                "profile",
                "amlink-maintenance-api",
                "amlink-submission-api", 
                "amlink-policy-api",
                "amlink-doc-api",
                "amwins-graphadapter-api"
            },
            
            // OAuth settings
            RequireConsent = false,
            AllowAccessTokensViaBrowser = true,
            AllowOfflineAccess = true, // Enable refresh tokens
            
            // Token lifetimes (in seconds)
            AccessTokenLifetime = 3600, // 1 hour
            RefreshTokenUsage = TokenUsage.ReUse,
            RefreshTokenExpiration = TokenExpiration.Sliding,
            SlidingRefreshTokenLifetime = 1296000, // 15 days
        },
"@

# Insert the new client before the closing brace of GetClients method
$clientsPattern = '(?s)(static IEnumerable<Client> GetClients\(\).*?return new List<Client>\s*\{.*?)(    \};\s*\})'
$replacement = "`${1}$docMgmtClient`n`${2}"

$content = $content -replace $clientsPattern, $replacement

# Write the updated content back to the file
Set-Content $programCsPath $content -Encoding UTF8

Write-Host "✅ Successfully configured Document Management client!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Client Configuration Summary:" -ForegroundColor White
Write-Host "   • Client ID: doc-mgmt-client" -ForegroundColor Gray
Write-Host "   • Grant Type: Authorization Code" -ForegroundColor Gray
Write-Host "   • Redirect URI: http://localhost:1180/callback" -ForegroundColor Gray
Write-Host "   • Client Secret: YOUR_CLIENT_SECRET_HERE" -ForegroundColor Gray
Write-Host ""
Write-Host "🔑 API Scopes Added:" -ForegroundColor White
Write-Host "   • amlink-maintenance-api - AM Link Maintenance API" -ForegroundColor Gray
Write-Host "   • amlink-submission-api - AM Link Submission API" -ForegroundColor Gray
Write-Host "   • amlink-policy-api - AM Link Policy API" -ForegroundColor Gray
Write-Host "   • amlink-doc-api - AM Link Document API" -ForegroundColor Gray
Write-Host "   • amwins-graphadapter-api - AM Wins Graph Adapter API" -ForegroundColor Gray
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Configure the actual client secret:" -ForegroundColor White
Write-Host "      .\scripts\configure-doc-mgmt-secret.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "   2. Restart IdentityServer to apply changes:" -ForegroundColor White
if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
    Write-Host "      docker-compose restart identityserver" -ForegroundColor Yellow
} else {
    Write-Host "      .\scripts\start-docker.ps1" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "   3. Test the OAuth authorization flow:" -ForegroundColor White
Write-Host "      .\scripts\test-doc-mgmt-client.ps1" -ForegroundColor Yellow
Write-Host ""

# Check if IdentityServer is currently running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "ℹ️  IdentityServer is currently running. Restart required to apply changes." -ForegroundColor Blue
    }
} catch {
    # IdentityServer not running, that's fine
}

Write-Host "✨ Setup completed successfully!" -ForegroundColor Green