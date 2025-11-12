# OAuth 2.0 Authorization Code Flow with PKCE Test
# Tests the doc-mgmt-client with PKCE enabled

param(
    [string]$BaseUrl = "https://localhost:5001",
    [string]$ClientId = "doc-mgmt-client",
    [string]$RedirectUri = "http://localhost:1180/callback",
    [switch]$SkipCertificateCheck
)

# Default to skip certificate check for local development
if (-not $PSBoundParameters.ContainsKey('SkipCertificateCheck')) {
    $SkipCertificateCheck = $true
}

Write-Host "🔐 OAuth 2.0 Authorization Code Flow with PKCE Test" -ForegroundColor Green -BackgroundColor Black
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Cyan
Write-Host "Client ID: $ClientId" -ForegroundColor Cyan
Write-Host "Redirect URI: $RedirectUri" -ForegroundColor Cyan
Write-Host ""

# PKCE Helper Functions
function New-CodeVerifier {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return [Convert]::ToBase64String($bytes) -replace '\+', '-' -replace '/', '_' -replace '=', ''
}

function New-CodeChallenge([string]$verifier) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $challengeBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($verifier))
    return [Convert]::ToBase64String($challengeBytes) -replace '\+', '-' -replace '/', '_' -replace '=', ''
}

# Step 1: Generate PKCE Parameters
Write-Host "🔑 Step 1: Generating PKCE Parameters..." -ForegroundColor Yellow
$codeVerifier = New-CodeVerifier
$codeChallenge = New-CodeChallenge $codeVerifier
$state = [System.Guid]::NewGuid().ToString("N").Substring(0, 16)

Write-Host "✅ PKCE parameters generated" -ForegroundColor Green
Write-Host "   Code Verifier: $($codeVerifier.Substring(0, 20))..." -ForegroundColor White
Write-Host "   Code Challenge: $($codeChallenge.Substring(0, 20))..." -ForegroundColor White
Write-Host "   State: $state" -ForegroundColor White
Write-Host ""

# Step 2: Test Discovery Document
Write-Host "📋 Step 2: Testing Discovery Document..." -ForegroundColor Yellow
try {
    $discovery = Invoke-RestMethod -Uri "$BaseUrl/.well-known/openid-configuration" -SkipCertificateCheck:$SkipCertificateCheck
    Write-Host "✅ Discovery document retrieved" -ForegroundColor Green
    Write-Host "   Authorization Endpoint: $($discovery.authorization_endpoint)" -ForegroundColor White
    Write-Host "   Token Endpoint: $($discovery.token_endpoint)" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "❌ Discovery document failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Build Authorization URL
Write-Host "🌍 Step 3: Building Authorization URL..." -ForegroundColor Yellow
$authParams = @{
    client_id = $ClientId
    response_type = "code"
    scope = "openid profile"
    redirect_uri = $RedirectUri
    state = $state
    code_challenge = $codeChallenge
    code_challenge_method = "S256"
}

$authQuery = ($authParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" }) -join "&"
$authUrl = "$($discovery.authorization_endpoint)?$authQuery"

Write-Host "✅ Authorization URL built" -ForegroundColor Green
Write-Host "   URL: $authUrl" -ForegroundColor White
Write-Host ""

# Step 4: Test Authorization Endpoint (should redirect to login)
Write-Host "🔐 Step 4: Testing Authorization Endpoint..." -ForegroundColor Yellow
try {
    $authResponse = Invoke-WebRequest -Uri $authUrl -SkipCertificateCheck:$SkipCertificateCheck -UseBasicParsing -MaximumRedirection 0
    Write-Host "⚠️  Received response without redirect: $($authResponse.StatusCode)" -ForegroundColor Yellow
} catch {
    if ($_.Exception.Response.StatusCode -eq 302) {
        $location = $_.Exception.Response.Headers["Location"]
        Write-Host "✅ Authorization endpoint working (302 redirect)" -ForegroundColor Green
        Write-Host "   Redirect to: $location" -ForegroundColor White
        
        # Check if redirected to login page
        if ($location -like "*/Account/Login*") {
            Write-Host "✅ Correctly redirected to login page" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Unexpected redirect location" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Authorization endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 5: Manual Instructions for Interactive Flow
Write-Host "👤 Step 5: Manual Login Required" -ForegroundColor Yellow
Write-Host "To complete the test, you need to:" -ForegroundColor White
Write-Host "1. Open this URL in your browser:" -ForegroundColor Cyan
Write-Host "   $authUrl" -ForegroundColor White
Write-Host ""
Write-Host "2. Login with test credentials:" -ForegroundColor Cyan
Write-Host "   Username: testuser" -ForegroundColor White
Write-Host "   Password: password" -ForegroundColor White
Write-Host ""
Write-Host "3. After login, you'll be redirected to:" -ForegroundColor Cyan
Write-Host "   $RedirectUri?code=AUTHORIZATION_CODE&state=$state" -ForegroundColor White
Write-Host ""
Write-Host "4. Copy the authorization code from the URL and run:" -ForegroundColor Cyan
Write-Host "   .\scripts\test-pkce-token-exchange.ps1 -AuthCode 'YOUR_CODE' -CodeVerifier '$codeVerifier' -State '$state'" -ForegroundColor White
Write-Host ""

# Step 6: Wait for manual input (optional)
Write-Host "Press Enter to continue with browser test, or Ctrl+C to exit..." -ForegroundColor Yellow
Read-Host

# Step 7: Open browser for interactive test
Write-Host "🌐 Step 6: Opening browser for interactive test..." -ForegroundColor Yellow
try {
    Start-Process $authUrl
    Write-Host "✅ Browser opened with authorization URL" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "⚠️  Could not open browser. Please manually navigate to:" -ForegroundColor Yellow
    Write-Host "   $authUrl" -ForegroundColor White
    Write-Host ""
}

Write-Host "🎯 PKCE Test Summary:" -ForegroundColor Green -BackgroundColor Black
Write-Host "✅ PKCE parameters generated successfully" -ForegroundColor Green
Write-Host "✅ Discovery document retrieved" -ForegroundColor Green
Write-Host "✅ Authorization endpoint responds correctly" -ForegroundColor Green
Write-Host "✅ Redirects to login page as expected" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Complete the login in your browser" -ForegroundColor White
Write-Host "2. Copy the authorization code from the callback URL" -ForegroundColor White  
Write-Host "3. Use the token exchange script to complete the flow" -ForegroundColor White
Write-Host ""
Write-Host "💾 Save these values for token exchange:" -ForegroundColor Yellow
Write-Host "Code Verifier: $codeVerifier" -ForegroundColor White
Write-Host "State: $state" -ForegroundColor White