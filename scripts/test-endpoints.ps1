#Requires -Version 5.1
<#
.SYNOPSIS
    Basic endpoint connectivity tests for IdentityServer4

.DESCRIPTION
    Tests basic connectivity to IdentityServer4 endpoints including HTTP/HTTPS
    base URLs and discovery endpoints.

.PARAMETER BaseUrl
    The base URL of the IdentityServer4 instance (default: https://localhost:5001)

.EXAMPLE
    .\test-endpoints.ps1
    
.EXAMPLE
    .\test-endpoints.ps1 -BaseUrl "https://myserver:5001"
#>

param(
    [string]$BaseUrl = "https://localhost:5001"
)

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

Write-Host "IdentityServer4 Basic Endpoint Tests" -ForegroundColor $Cyan
Write-Host "====================================" -ForegroundColor $Cyan
Write-Host "Base URL: $BaseUrl" -ForegroundColor $Yellow
Write-Host ""

# Skip SSL certificate validation for development
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $PSDefaultParameterValues['Invoke-RestMethod:SkipCertificateCheck'] = $true
    $PSDefaultParameterValues['Invoke-WebRequest:SkipCertificateCheck'] = $true
} else {
    # For Windows PowerShell 5.1
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
}

function Test-Endpoint {
    param(
        [string]$Url,
        [string]$Description,
        [int]$ExpectedStatusCode = 200
    )
    
    Write-Host "Testing: $Description" -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 10 -ErrorAction Stop
        
        if ($response.StatusCode -eq $ExpectedStatusCode) {
            Write-Host " ✅ PASS" -ForegroundColor $Green
            Write-Host "  Status: $($response.StatusCode)" -ForegroundColor $Green
            return $true
        } else {
            Write-Host " ❌ FAIL" -ForegroundColor $Red
            Write-Host "  Expected: $ExpectedStatusCode, Got: $($response.StatusCode)" -ForegroundColor $Red
            return $false
        }
    }
    catch {
        Write-Host " ❌ FAIL" -ForegroundColor $Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor $Red
        return $false
    }
}

# Test results tracking
$results = @()

# Test HTTP base URL (if using localhost)
if ($BaseUrl -like "*localhost*") {
    $httpUrl = $BaseUrl -replace "https://", "http://" -replace ":5001", ":5000"
    $results += Test-Endpoint -Url $httpUrl -Description "HTTP Base URL ($httpUrl)"
}

# Test HTTPS base URL
$results += Test-Endpoint -Url $BaseUrl -Description "HTTPS Base URL ($BaseUrl)"

# Test discovery endpoint
$discoveryUrl = "$BaseUrl/.well-known/openid-configuration"
$results += Test-Endpoint -Url $discoveryUrl -Description "Discovery Endpoint"

# Test JWKS endpoint (if discovery works)
if ($results[-1]) {
    try {
        $discovery = Invoke-RestMethod -Uri $discoveryUrl -ErrorAction Stop
        if ($discovery.jwks_uri) {
            $results += Test-Endpoint -Url $discovery.jwks_uri -Description "JWKS Endpoint"
        }
    }
    catch {
        Write-Host "Could not retrieve JWKS endpoint from discovery document" -ForegroundColor $Yellow
    }
}

# Summary
Write-Host ""
Write-Host "Test Summary" -ForegroundColor $Cyan
Write-Host "============" -ForegroundColor $Cyan

$passed = ($results | Where-Object { $_ -eq $true }).Count
$total = $results.Count

if ($passed -eq $total) {
    Write-Host "All tests passed! ✅ ($passed/$total)" -ForegroundColor $Green
    $exitCode = 0
} else {
    Write-Host "Some tests failed ❌ ($passed/$total)" -ForegroundColor $Red
    $exitCode = 1
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor $Yellow
Write-Host "- Run 'test-auth-flows.ps1' for comprehensive authentication testing"
Write-Host "- Check the server logs if any tests failed"
Write-Host "- Verify the IdentityServer4 application is running"

exit $exitCode