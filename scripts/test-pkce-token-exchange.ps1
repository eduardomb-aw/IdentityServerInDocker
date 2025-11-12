# OAuth 2.0 Token Exchange with PKCE
# Exchanges authorization code for tokens using PKCE

param(
    [Parameter(Mandatory=$true)]
    [string]$AuthCode,
    
    [Parameter(Mandatory=$true)]
    [string]$CodeVerifier,
    
    [Parameter(Mandatory=$true)]
    [string]$State,
    
    [string]$BaseUrl = "https://localhost:5001",
    [string]$ClientId = "doc-mgmt-client",
    [string]$RedirectUri = "http://localhost:1180/callback",
    [switch]$SkipCertificateCheck
)

Write-Host "🔄 OAuth 2.0 Token Exchange with PKCE" -ForegroundColor Green -BackgroundColor Black
Write-Host "=" * 50 -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Cyan
Write-Host "Client ID: $ClientId" -ForegroundColor Cyan
Write-Host "Auth Code: $($AuthCode.Substring(0, 20))..." -ForegroundColor Cyan
Write-Host "State: $State" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get Discovery Document
Write-Host "📋 Step 1: Getting Token Endpoint..." -ForegroundColor Yellow
try {
    $discovery = Invoke-RestMethod -Uri "$BaseUrl/.well-known/openid-configuration" -SkipCertificateCheck:$SkipCertificateCheck
    Write-Host "✅ Token endpoint: $($discovery.token_endpoint)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Discovery failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Default to skip certificate check for local development
if (-not $PSBoundParameters.ContainsKey('SkipCertificateCheck')) {
    $SkipCertificateCheck = $true
}

# Step 2: Exchange Code for Tokens
Write-Host "🎟️  Step 2: Exchanging Authorization Code for Tokens..." -ForegroundColor Yellow
try {
    # Get client secret from user secrets
    $clientSecret = ""
    try {
        $secretsJson = dotnet user-secrets list --project "src/IdentityServer" 2>$null
        if ($secretsJson) {
            $secretsJson | ForEach-Object {
                if ($_ -match "DocumentManagement:ClientSecret = (.+)") {
                    $clientSecret = $Matches[1]
                }
            }
        }
    } catch {
        Write-Host "⚠️  Could not retrieve client secret from user secrets" -ForegroundColor Yellow
    }
    
    if (-not $clientSecret) {
        Write-Host "⚠️  No client secret found, using fallback" -ForegroundColor Yellow
        $clientSecret = "YOUR_CLIENT_SECRET_HERE"
    }
    
    $tokenBody = @{
        grant_type = "authorization_code"
        client_id = $ClientId
        client_secret = $clientSecret
        code = $AuthCode
        redirect_uri = $RedirectUri
        code_verifier = $CodeVerifier
    }
    
    $tokenResponse = Invoke-RestMethod -Uri $discovery.token_endpoint -Method Post -Body $tokenBody -ContentType 'application/x-www-form-urlencoded' -SkipCertificateCheck:$SkipCertificateCheck
    
    Write-Host "✅ Token exchange successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 Token Response:" -ForegroundColor Cyan
    Write-Host "   Token Type: $($tokenResponse.token_type)" -ForegroundColor White
    Write-Host "   Expires In: $($tokenResponse.expires_in) seconds" -ForegroundColor White
    Write-Host "   Scope: $($tokenResponse.scope)" -ForegroundColor White
    
    if ($tokenResponse.access_token) {
        Write-Host "   Access Token (first 50 chars): $($tokenResponse.access_token.Substring(0, 50))..." -ForegroundColor White
        
        # Decode Access Token
        Write-Host ""
        Write-Host "🔍 Access Token Claims:" -ForegroundColor Yellow
        try {
            $tokenParts = $tokenResponse.access_token.Split('.')
            $payload = $tokenParts[1]
            while ($payload.Length % 4) { $payload += "=" }
            $decodedBytes = [System.Convert]::FromBase64String($payload)
            $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            $tokenData = $decodedText | ConvertFrom-Json
            
            $tokenData.PSObject.Properties | ForEach-Object {
                Write-Host "     $($_.Name): $($_.Value)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "   Could not decode access token" -ForegroundColor Yellow
        }
    }
    
    if ($tokenResponse.id_token) {
        Write-Host ""
        Write-Host "   ID Token (first 50 chars): $($tokenResponse.id_token.Substring(0, 50))..." -ForegroundColor White
        
        # Decode ID Token
        Write-Host ""
        Write-Host "🔍 ID Token Claims:" -ForegroundColor Yellow
        try {
            $idTokenParts = $tokenResponse.id_token.Split('.')
            $idPayload = $idTokenParts[1]
            while ($idPayload.Length % 4) { $idPayload += "=" }
            $idDecodedBytes = [System.Convert]::FromBase64String($idPayload)
            $idDecodedText = [System.Text.Encoding]::UTF8.GetString($idDecodedBytes)
            $idTokenData = $idDecodedText | ConvertFrom-Json
            
            $idTokenData.PSObject.Properties | ForEach-Object {
                Write-Host "     $($_.Name): $($_.Value)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "   Could not decode ID token" -ForegroundColor Yellow
        }
    }
    
    if ($tokenResponse.refresh_token) {
        Write-Host ""
        Write-Host "   Refresh Token: Available" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Token exchange failed!" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.ErrorDetails.Message) {
        try {
            $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "   OAuth Error: $($errorDetails.error)" -ForegroundColor Red
            if ($errorDetails.error_description) {
                Write-Host "   Description: $($errorDetails.error_description)" -ForegroundColor Red
            }
        } catch {
            Write-Host "   Raw Error: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }
    exit 1
}

Write-Host ""
Write-Host "🎉 PKCE Flow Complete!" -ForegroundColor Green -BackgroundColor Black
Write-Host "✅ Authorization Code exchanged successfully" -ForegroundColor Green
Write-Host "✅ Access Token received" -ForegroundColor Green
Write-Host "✅ ID Token received (OpenID Connect)" -ForegroundColor Green
Write-Host "✅ PKCE validation passed" -ForegroundColor Green