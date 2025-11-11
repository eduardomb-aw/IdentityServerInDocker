#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Demonstrates OAuth 2.0 Authorization Code flow with the Document Management client.

.DESCRIPTION
    This script provides a practical example of how to implement OAuth 2.0 Authorization Code flow
    with the configured Document Management client. It can be used as a reference for your application integration.

.PARAMETER BaseUrl
    The base URL of the IdentityServer instance. Defaults to https://localhost:5001

.PARAMETER Interactive
    Run in interactive mode to actually perform OAuth flow with a browser

.EXAMPLE
    .\scripts\demo-doc-mgmt-oauth.ps1
    Shows the OAuth flow steps without executing them
    
.EXAMPLE
    .\scripts\demo-doc-mgmt-oauth.ps1 -Interactive
    Opens browser for actual OAuth flow demonstration
#>

param(
    [Parameter(HelpMessage = "Base URL of the IdentityServer instance")]
    [string]$BaseUrl = "https://localhost:5001",
    
    [Parameter(HelpMessage = "Run in interactive mode with browser")]
    [switch]$Interactive
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 Document Management OAuth 2.0 Integration Demo" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# Client configuration
$clientId = "doc-mgmt-client"

# Try to get client secret from User Secrets
$clientSecret = "YOUR_CLIENT_SECRET_HERE"
try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $rootDir = Split-Path -Parent $scriptDir
    Push-Location "$rootDir\src\IdentityServer"
    $userSecretsJson = dotnet user-secrets list --json 2>$null
    if ($LASTEXITCODE -eq 0 -and $userSecretsJson) {
        $secrets = $userSecretsJson | ConvertFrom-Json
        if ($secrets."DocumentManagement:ClientSecret") {
            $clientSecret = $secrets."DocumentManagement:ClientSecret"
        }
    }
    Pop-Location
} catch {
    # Fallback to environment variable or placeholder
    $clientSecret = $env:DOC_MGMT_CLIENT_SECRET ?? "YOUR_CLIENT_SECRET_HERE"
}
$redirectUri = "http://localhost:1180/callback"
$scopes = @(
    "openid",
    "profile", 
    "amlink-maintenance-api",
    "amlink-submission-api",
    "amlink-policy-api", 
    "amlink-doc-api",
    "amwins-graphadapter-api"
)

Write-Host "📋 Client Configuration:" -ForegroundColor Yellow
Write-Host "   • Client ID: $clientId" -ForegroundColor Gray
Write-Host "   • Redirect URI: $redirectUri" -ForegroundColor Gray
Write-Host "   • Scopes: $($scopes -join ', ')" -ForegroundColor Gray
Write-Host ""

# Generate state and nonce for security
$state = [System.Guid]::NewGuid().ToString("N")
$nonce = [System.Guid]::NewGuid().ToString("N")

Write-Host "🔐 Security Parameters:" -ForegroundColor Yellow
Write-Host "   • State: $state" -ForegroundColor Gray
Write-Host "   • Nonce: $nonce" -ForegroundColor Gray
Write-Host ""

# Step 1: Build Authorization URL
$scopeString = $scopes -join " "
$authParams = @{
    "client_id" = $clientId
    "response_type" = "code"
    "scope" = $scopeString
    "redirect_uri" = $redirectUri
    "state" = $state
    "nonce" = $nonce
}

$queryString = ($authParams.GetEnumerator() | ForEach-Object { 
    "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" 
}) -join "&"

$authUrl = "$BaseUrl/connect/authorize?$queryString"

Write-Host "🌐 Step 1: Authorization Request" -ForegroundColor Cyan
Write-Host "   Redirect user to:" -ForegroundColor White
Write-Host "   $authUrl" -ForegroundColor Blue
Write-Host ""

if ($Interactive) {
    Write-Host "🌐 Opening browser for interactive demo..." -ForegroundColor Green
    Start-Process $authUrl
    Write-Host ""
    Write-Host "👤 Please complete the login process in your browser." -ForegroundColor Yellow
    Write-Host "   After login, you'll be redirected to: $redirectUri" -ForegroundColor Gray
    Write-Host ""
    
    # Prompt for authorization code
    $authCode = Read-Host "📝 Enter the 'code' parameter from the callback URL"
    
    if ([string]::IsNullOrWhiteSpace($authCode)) {
        Write-Host "❌ No authorization code provided. Demo stopped." -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "🔄 Step 2: Token Exchange" -ForegroundColor Cyan
    
    # Step 2: Exchange code for tokens
    $tokenParams = @{
        grant_type = "authorization_code"
        code = $authCode
        client_id = $clientId
        client_secret = $clientSecret
        redirect_uri = $redirectUri
    }
    
    try {
        Write-Host "   Making token request..." -ForegroundColor White
        $tokenResponse = Invoke-RestMethod -Uri "$BaseUrl/connect/token" -Method Post -Body $tokenParams -ContentType "application/x-www-form-urlencoded" -SkipCertificateCheck
        
        Write-Host "   ✅ Token exchange successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎟️  Received Tokens:" -ForegroundColor Yellow
        Write-Host "   • Access Token: $($tokenResponse.access_token.Substring(0, 50))..." -ForegroundColor Gray
        Write-Host "   • Token Type: $($tokenResponse.token_type)" -ForegroundColor Gray
        Write-Host "   • Expires In: $($tokenResponse.expires_in) seconds" -ForegroundColor Gray
        
        if ($tokenResponse.refresh_token) {
            Write-Host "   • Refresh Token: $($tokenResponse.refresh_token.Substring(0, 30))..." -ForegroundColor Gray
        }
        
        if ($tokenResponse.id_token) {
            Write-Host "   • ID Token: $($tokenResponse.id_token.Substring(0, 30))..." -ForegroundColor Gray
        }
        
        # Step 3: Use the access token
        Write-Host ""
        Write-Host "🔑 Step 3: Using Access Token" -ForegroundColor Cyan
        Write-Host "   Include in API requests as:" -ForegroundColor White
        Write-Host "   Authorization: Bearer $($tokenResponse.access_token)" -ForegroundColor Blue
        
        # Demonstrate UserInfo endpoint call
        try {
            Write-Host ""
            Write-Host "👤 Testing UserInfo endpoint..." -ForegroundColor Yellow
            $headers = @{ Authorization = "Bearer $($tokenResponse.access_token)" }
            $userInfo = Invoke-RestMethod -Uri "$BaseUrl/connect/userinfo" -Headers $headers -SkipCertificateCheck
            
            Write-Host "   ✅ UserInfo response:" -ForegroundColor Green
            $userInfo.PSObject.Properties | ForEach-Object {
                Write-Host "      • $($_.Name): $($_.Value)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "   ⚠️  UserInfo call failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "   ❌ Token exchange failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} else {
    Write-Host "💡 Step 2: Handle Callback" -ForegroundColor Cyan
    Write-Host "   After user login, IdentityServer will redirect to:" -ForegroundColor White
    Write-Host "   $redirectUri?code=[AUTHORIZATION_CODE]&state=$state" -ForegroundColor Blue
    Write-Host ""
    
    Write-Host "🔄 Step 3: Exchange Code for Tokens" -ForegroundColor Cyan
    Write-Host "   POST $BaseUrl/connect/token" -ForegroundColor White
    Write-Host "   Content-Type: application/x-www-form-urlencoded" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Body parameters:" -ForegroundColor White
    Write-Host "   grant_type=authorization_code" -ForegroundColor Gray
    Write-Host "   code=[AUTHORIZATION_CODE_FROM_CALLBACK]" -ForegroundColor Gray
    Write-Host "   client_id=$clientId" -ForegroundColor Gray
    Write-Host "   client_secret=$clientSecret" -ForegroundColor Gray
    Write-Host "   redirect_uri=$redirectUri" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📋 Expected Token Response:" -ForegroundColor Cyan
    $sampleResponse = @{
        access_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIs..."
        token_type = "Bearer"
        expires_in = 3600
        refresh_token = "CfDJ8KcnKZxBN3gO-kLwWx2QJxf..."
        id_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIs..."
        scope = $scopeString
    } | ConvertTo-Json -Depth 2
    
    Write-Host $sampleResponse -ForegroundColor Blue
    Write-Host ""
}

Write-Host "🛠️  Implementation Code Examples:" -ForegroundColor Cyan
Write-Host ""

Write-Host "📝 C# Example:" -ForegroundColor Yellow
Write-Host @"
// Step 1: Redirect to authorization endpoint
var authUrl = `$"$BaseUrl/connect/authorize?" +
    `$"client_id=$clientId&" +
    `$"response_type=code&" +
    `$"scope={Uri.EscapeDataString("$scopeString")}&" +
    `$"redirect_uri={Uri.EscapeDataString("$redirectUri")}&" +
    `$"state={state}&" +
    `$"nonce={nonce}";

// Step 2: Exchange code for tokens (in callback handler)
var tokenResponse = await httpClient.PostAsync("$BaseUrl/connect/token", new FormUrlEncodedContent(new[]
{
    new KeyValuePair<string, string>("grant_type", "authorization_code"),
    new KeyValuePair<string, string>("code", authorizationCode),
    new KeyValuePair<string, string>("client_id", "$clientId"),
    new KeyValuePair<string, string>("client_secret", "$clientSecret"),
    new KeyValuePair<string, string>("redirect_uri", "$redirectUri")
}));

// Step 3: Use access token in API calls
httpClient.DefaultRequestHeaders.Authorization = 
    new AuthenticationHeaderValue("Bearer", accessToken);
"@ -ForegroundColor Blue

Write-Host ""
Write-Host "📝 JavaScript Example:" -ForegroundColor Yellow
Write-Host @"
// Step 1: Redirect to authorization endpoint
const authUrl = '$BaseUrl/connect/authorize?' +
    'client_id=$clientId&' +
    'response_type=code&' +
    'scope=' + encodeURIComponent('$scopeString') + '&' +
    'redirect_uri=' + encodeURIComponent('$redirectUri') + '&' +
    'state=$state&' +
    'nonce=$nonce';

window.location.href = authUrl;

// Step 2: Exchange code for tokens (in callback handler)
const tokenResponse = await fetch('$BaseUrl/connect/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
        grant_type: 'authorization_code',
        code: authorizationCode,
        client_id: '$clientId',
        client_secret: '$clientSecret',
        redirect_uri: '$redirectUri'
    })
});

// Step 3: Use access token in API calls
const apiResponse = await fetch('https://api.example.com/data', {
    headers: { 'Authorization': `Bearer `${accessToken}` }
});
"@ -ForegroundColor Blue

Write-Host ""
Write-Host "🔒 Security Best Practices:" -ForegroundColor Red
Write-Host "   ✅ Always validate the 'state' parameter to prevent CSRF attacks" -ForegroundColor White
Write-Host "   ✅ Store client secret securely (use Azure Key Vault or similar)" -ForegroundColor White
Write-Host "   ✅ Use HTTPS for all redirect URIs in production" -ForegroundColor White
Write-Host "   ✅ Implement PKCE for additional security (recommended)" -ForegroundColor White
Write-Host "   ✅ Validate ID token signature and claims" -ForegroundColor White
Write-Host "   ✅ Use refresh tokens to maintain long-lived sessions" -ForegroundColor White

Write-Host ""
Write-Host "✨ Document Management OAuth 2.0 integration demo completed!" -ForegroundColor Green

if (-not $Interactive) {
    Write-Host ""
    Write-Host "💡 Run with -Interactive flag to test the actual OAuth flow:" -ForegroundColor Blue
    Write-Host "   .\scripts\demo-doc-mgmt-oauth.ps1 -Interactive" -ForegroundColor Yellow
}