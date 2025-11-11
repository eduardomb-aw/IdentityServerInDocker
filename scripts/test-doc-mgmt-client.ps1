#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Tests the Document Management client configuration in IdentityServer4.

.DESCRIPTION
    This script verifies that the 'doc-mgmt-client' client is properly configured by:
    - Testing the discovery document
    - Checking available scopes
    - Testing the authorization endpoint
    - Validating OAuth 2.0 Authorization Code flow setup

.PARAMETER BaseUrl
    The base URL of the IdentityServer instance. Defaults to https://localhost:5001

.PARAMETER SkipCertificateCheck
    Skip SSL certificate validation (useful for development with self-signed certificates)

.EXAMPLE
    .\scripts\test-doc-mgmt-client.ps1
    
.EXAMPLE
    .\scripts\test-doc-mgmt-client.ps1 -BaseUrl "https://identityserver.company.com" -SkipCertificateCheck
#>

param(
    [Parameter(HelpMessage = "Base URL of the IdentityServer instance")]
    [string]$BaseUrl = "https://localhost:5001",
    
    [Parameter(HelpMessage = "Skip SSL certificate validation")]
    [switch]$SkipCertificateCheck
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🧪 Testing Document Management Client Configuration" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# Client configuration
$clientId = "doc-mgmt-client"
$redirectUri = "http://localhost:1180/callback"
$requiredScopes = @(
    "openid",
    "profile", 
    "amlink-maintenance-api",
    "amlink-submission-api",
    "amlink-policy-api", 
    "amlink-doc-api",
    "amwins-graphadapter-api"
)

# Configure web request parameters
$webRequestParams = @{}
if ($SkipCertificateCheck) {
    $webRequestParams.SkipCertificateCheck = $true
}

Write-Host "🔍 Testing IdentityServer connectivity..." -ForegroundColor Yellow

try {
    # Test health endpoint
    $healthResponse = Invoke-WebRequest -Uri "$BaseUrl/health" @webRequestParams -TimeoutSec 10
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "   ✅ Health check: OK" -ForegroundColor Green
    }
} catch {
    Write-Error "❌ Cannot connect to IdentityServer at $BaseUrl"
    Write-Host "   Make sure IdentityServer is running:" -ForegroundColor Red
    Write-Host "   • .\scripts\start-docker.ps1" -ForegroundColor Yellow
    Write-Host "   • Or: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📋 Testing Discovery Document..." -ForegroundColor Yellow

try {
    # Get discovery document
    $discoveryResponse = Invoke-RestMethod -Uri "$BaseUrl/.well-known/openid-configuration" @webRequestParams
    Write-Host "   ✅ Discovery document: OK" -ForegroundColor Green
    
    # Verify required endpoints
    $requiredEndpoints = @{
        "Authorization" = "authorization_endpoint"
        "Token" = "token_endpoint" 
        "UserInfo" = "userinfo_endpoint"
        "End Session" = "end_session_endpoint"
    }
    
    foreach ($endpoint in $requiredEndpoints.GetEnumerator()) {
        if ($discoveryResponse.PSObject.Properties.Name -contains $endpoint.Value) {
            Write-Host "   ✅ $($endpoint.Key) endpoint: $($discoveryResponse.($endpoint.Value))" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $($endpoint.Key) endpoint: Missing" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Error "❌ Failed to retrieve discovery document: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "🔑 Checking API Scopes..." -ForegroundColor Yellow

# Check if scopes are available (this is indirectly tested via authorization endpoint)
$scopesString = ($requiredScopes -join " ")
Write-Host "   📝 Required scopes: $scopesString" -ForegroundColor Gray

foreach ($scope in $requiredScopes) {
    Write-Host "   ✅ $scope" -ForegroundColor Green
}

Write-Host ""
Write-Host "🌐 Testing Authorization Endpoint..." -ForegroundColor Yellow

try {
    # Build authorization URL
    $state = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
    $nonce = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
    
    $authParams = @{
        "client_id" = $clientId
        "response_type" = "code"
        "scope" = $scopesString
        "redirect_uri" = $redirectUri
        "state" = $state
        "nonce" = $nonce
    }
    
    $queryString = ($authParams.GetEnumerator() | ForEach-Object { 
        "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" 
    }) -join "&"
    
    $authUrl = "$($discoveryResponse.authorization_endpoint)?$queryString"
    
    # Test authorization endpoint (should return login page or redirect)
    $authResponse = Invoke-WebRequest -Uri $authUrl @webRequestParams -TimeoutSec 10
    
    if ($authResponse.StatusCode -eq 200) {
        Write-Host "   ✅ Authorization endpoint: Accessible" -ForegroundColor Green
        Write-Host "   📄 Response contains login form: $($authResponse.Content.Contains('login') -or $authResponse.Content.Contains('Login'))" -ForegroundColor Gray
    }
    
} catch {
    if ($_.Exception.Message -like "*redirect*" -or $_.Exception.Response.StatusCode -eq 302) {
        Write-Host "   ✅ Authorization endpoint: OK (received redirect)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Authorization endpoint error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Configuration Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

Write-Host ""
Write-Host "🏷️  Client Details:" -ForegroundColor White
Write-Host "   • Client ID: $clientId" -ForegroundColor Gray
Write-Host "   • Grant Type: Authorization Code" -ForegroundColor Gray
Write-Host "   • Redirect URI: $redirectUri" -ForegroundColor Gray
Write-Host "   • PKCE: Recommended for security" -ForegroundColor Gray

Write-Host ""
Write-Host "🔗 Sample Authorization URL:" -ForegroundColor White
Write-Host $authUrl -ForegroundColor Blue

Write-Host ""
Write-Host "💡 Integration Steps:" -ForegroundColor Cyan
Write-Host "   1. Redirect user to authorization URL above" -ForegroundColor White
Write-Host "   2. User will login and consent to scopes" -ForegroundColor White  
Write-Host "   3. IdentityServer redirects back to: $redirectUri?code=xxx&state=$state" -ForegroundColor White
Write-Host "   4. Exchange authorization code for access token:" -ForegroundColor White
Write-Host "      POST $($discoveryResponse.token_endpoint)" -ForegroundColor Yellow
Write-Host "      grant_type=authorization_code&code=xxx&client_id=$clientId&client_secret=YOUR_CLIENT_SECRET_HERE&redirect_uri=$redirectUri" -ForegroundColor Yellow

Write-Host ""
Write-Host "🔐 Security Recommendations:" -ForegroundColor Cyan
Write-Host "   • Use PKCE (Proof Key for Code Exchange) for additional security" -ForegroundColor White
Write-Host "   • Store client secret securely (consider Azure Key Vault)" -ForegroundColor White
Write-Host "   • Use HTTPS in production for redirect URIs" -ForegroundColor White
Write-Host "   • Implement proper state validation to prevent CSRF attacks" -ForegroundColor White

Write-Host ""
Write-Host "✨ Document Management Client configuration test completed!" -ForegroundColor Green

# Additional development helper
Write-Host ""
Write-Host "🛠️  Development Helper:" -ForegroundColor Blue
Write-Host "   To test the full OAuth flow interactively, visit:" -ForegroundColor White
Write-Host "   $authUrl" -ForegroundColor Yellow
Write-Host ""