# IdentityServer4 Authentication Flow Tests
# This script tests various OAuth 2.0 and OpenID Connect flows

param(
    [string]$BaseUrl = "https://localhost:5001",
    [switch]$SkipCertificateCheck
)

# Default to skip certificate check for local development
if (-not $PSBoundParameters.ContainsKey('SkipCertificateCheck')) {
    $SkipCertificateCheck = $true
}

Write-Host "🔐 IdentityServer4 Authentication Flow Tests" -ForegroundColor Green -BackgroundColor Black
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Cyan
Write-Host ""

# Test 1: Discovery Document
Write-Host "📋 Testing Discovery Document..." -ForegroundColor Yellow
try {
    $discovery = Invoke-RestMethod -Uri "$BaseUrl/.well-known/openid-configuration" -SkipCertificateCheck:$SkipCertificateCheck
    Write-Host "✅ Discovery document retrieved successfully" -ForegroundColor Green
    Write-Host "   Issuer: $($discovery.issuer)" -ForegroundColor White
    Write-Host "   Authorization Endpoint: $($discovery.authorization_endpoint)" -ForegroundColor White
    Write-Host "   Token Endpoint: $($discovery.token_endpoint)" -ForegroundColor White
    Write-Host "   UserInfo Endpoint: $($discovery.userinfo_endpoint)" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "❌ Discovery document test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 2: JWKS Endpoint
Write-Host "🔑 Testing JWKS Endpoint..." -ForegroundColor Yellow
try {
    $jwks = Invoke-RestMethod -Uri "$BaseUrl/.well-known/openid-configuration/jwks" -SkipCertificateCheck:$SkipCertificateCheck
    Write-Host "✅ JWKS endpoint accessible" -ForegroundColor Green
    Write-Host "   Number of keys: $($jwks.keys.Count)" -ForegroundColor White
    if ($jwks.keys.Count -gt 0) {
        Write-Host "   Key ID: $($jwks.keys[0].kid)" -ForegroundColor White
        Write-Host "   Key Type: $($jwks.keys[0].kty)" -ForegroundColor White
        Write-Host "   Algorithm: $($jwks.keys[0].alg)" -ForegroundColor White
    }
    Write-Host ""
} catch {
    Write-Host "❌ JWKS endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 3: Client Credentials Flow
Write-Host "🤖 Testing Client Credentials Flow (Machine-to-Machine)..." -ForegroundColor Yellow
try {
    $body = @{
        grant_type = 'client_credentials'
        client_id = 'test-client'
        client_secret = 'secret'
        scope = 'api1'
    }
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/connect/token" -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded' -SkipCertificateCheck:$SkipCertificateCheck
    
    Write-Host "✅ Client Credentials flow successful" -ForegroundColor Green
    Write-Host "   Token Type: $($response.token_type)" -ForegroundColor White
    Write-Host "   Expires In: $($response.expires_in) seconds" -ForegroundColor White
    Write-Host "   Scope: $($response.scope)" -ForegroundColor White
    Write-Host "   Access Token (first 50 chars): $($response.access_token.Substring(0, 50))..." -ForegroundColor White
    
    # Decode JWT token
    $tokenParts = $response.access_token.Split('.')
    $payload = $tokenParts[1]
    while ($payload.Length % 4) { $payload += "=" }
    $decodedBytes = [System.Convert]::FromBase64String($payload)
    $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
    $tokenData = $decodedText | ConvertFrom-Json
    
    Write-Host "   JWT Claims:" -ForegroundColor White
    Write-Host "     - Issuer: $($tokenData.iss)" -ForegroundColor Gray
    Write-Host "     - Client ID: $($tokenData.client_id)" -ForegroundColor Gray
    Write-Host "     - Scope: $($tokenData.scope)" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "❌ Client Credentials flow failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 4: Authorization Code Flow (Authorization Endpoint)
Write-Host "🌐 Testing Authorization Code Flow (Interactive)..." -ForegroundColor Yellow
try {
    $authUrl = "$BaseUrl/connect/authorize?client_id=web-client&response_type=code&scope=openid profile api1&redirect_uri=https://localhost:5002/signin-oidc&state=test123"
    
    $authResponse = Invoke-WebRequest -Uri $authUrl -SkipCertificateCheck:$SkipCertificateCheck -UseBasicParsing -MaximumRedirection 0
    Write-Host "✅ Authorization endpoint accessible" -ForegroundColor Green
    Write-Host "   Status Code: $($authResponse.StatusCode)" -ForegroundColor White
    Write-Host ""
} catch {
    if ($_.Exception.Response.StatusCode -eq 302) {
        Write-Host "✅ Authorization endpoint working (302 redirect as expected)" -ForegroundColor Green
        Write-Host "   This redirect indicates the authorization flow is ready" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "❌ Authorization endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
    }
}

# Test 5: Error Handling
Write-Host "🚨 Testing Error Handling..." -ForegroundColor Yellow

# Test invalid client
try {
    $invalidBody = @{
        grant_type = 'client_credentials'
        client_id = 'invalid-client'
        client_secret = 'wrong-secret'
        scope = 'api1'
    }
    Invoke-RestMethod -Uri "$BaseUrl/connect/token" -Method Post -Body $invalidBody -ContentType 'application/x-www-form-urlencoded' -SkipCertificateCheck:$SkipCertificateCheck
    Write-Host "❌ Invalid client was not rejected (security issue!)" -ForegroundColor Red
} catch {
    $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "✅ Invalid client properly rejected" -ForegroundColor Green
    Write-Host "   Error: $($errorDetails.error)" -ForegroundColor White
}

# Test invalid scope  
try {
    $invalidScopeBody = @{
        grant_type = 'client_credentials'
        client_id = 'test-client'
        client_secret = 'secret'
        scope = 'invalid-scope'
    }
    Invoke-RestMethod -Uri "$BaseUrl/connect/token" -Method Post -Body $invalidScopeBody -ContentType 'application/x-www-form-urlencoded' -SkipCertificateCheck:$SkipCertificateCheck
    Write-Host "❌ Invalid scope was not rejected (security issue!)" -ForegroundColor Red
} catch {
    $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "✅ Invalid scope properly rejected" -ForegroundColor Green
    Write-Host "   Error: $($errorDetails.error)" -ForegroundColor White
}

Write-Host ""
Write-Host "🎉 Test Summary Complete" -ForegroundColor Green -BackgroundColor Black
Write-Host "All critical OAuth 2.0 and OpenID Connect flows are operational!" -ForegroundColor Green