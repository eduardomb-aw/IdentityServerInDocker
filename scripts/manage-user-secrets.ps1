#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Manages .NET User Secrets for the IdentityServer project.

.DESCRIPTION
    This script helps you securely manage User Secrets for the IdentityServer project,
    particularly for storing the Document Management client secret locally without
    committing it to the repository.

.PARAMETER Action
    The action to perform: Set, Get, List, or Clear

.PARAMETER Secret
    The client secret to set (only used with Set action)

.PARAMETER ShowValue
    Show the actual secret value when getting or listing (use with caution)

.EXAMPLE
    .\scripts\manage-user-secrets.ps1 -Action Set
    Prompts for the client secret and stores it securely
    
.EXAMPLE
    .\scripts\manage-user-secrets.ps1 -Action Get
    Shows the stored client secret (masked)
    
.EXAMPLE
    .\scripts\manage-user-secrets.ps1 -Action List
    Lists all user secrets for this project
    
.EXAMPLE
    .\scripts\manage-user-secrets.ps1 -Action Clear
    Removes all user secrets for this project
#>

param(
    [Parameter(Mandatory = $true, HelpMessage = "Action to perform")]
    [ValidateSet("Set", "Get", "List", "Clear")]
    [string]$Action,
    
    [Parameter(HelpMessage = "The client secret (for Set action)")]
    [SecureString]$Secret,
    
    [Parameter(HelpMessage = "Show actual secret values")]
    [switch]$ShowValue
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🔐 IdentityServer User Secrets Management" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$projectPath = Join-Path $rootDir "src\IdentityServer"

# Verify project exists
if (-not (Test-Path $projectPath)) {
    Write-Error "❌ IdentityServer project not found at: $projectPath"
    exit 1
}

# Check if dotnet CLI is available
try {
    $null = Get-Command dotnet -ErrorAction Stop
} catch {
    Write-Error "❌ .NET CLI (dotnet) not found. Please install .NET SDK."
    exit 1
}

# Navigate to project directory
Push-Location $projectPath

try {
    switch ($Action) {
        "Set" {
            Write-Host "🔑 Setting Document Management Client Secret" -ForegroundColor Yellow
            Write-Host ""
            
            $secretValue = $null
            if ($Secret) {
                $secretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret))
            } else {
                Write-Host "Please enter the Document Management client secret:" -ForegroundColor White
                $secureInput = Read-Host "Client Secret" -AsSecureString
                $secretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput))
            }
            
            if ([string]::IsNullOrWhiteSpace($secretValue)) {
                Write-Error "❌ No client secret provided"
                exit 1
            }
            
            # Set the user secret
            $result = dotnet user-secrets set "DocumentManagement:ClientSecret" $secretValue 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Client secret stored successfully in User Secrets!" -ForegroundColor Green
                Write-Host ""
                Write-Host "🔒 Security Info:" -ForegroundColor Blue
                Write-Host "   • Secret is stored locally in your user profile" -ForegroundColor Gray
                Write-Host "   • Secret is NOT committed to the repository" -ForegroundColor Gray
                Write-Host "   • Secret is available only on this machine for this user" -ForegroundColor Gray
            } else {
                Write-Error "❌ Failed to set user secret: $result"
            }
        }
        
        "Get" {
            Write-Host "🔍 Getting Document Management Client Secret" -ForegroundColor Yellow
            Write-Host ""
            
            $result = dotnet user-secrets list --json 2>&1
            if ($LASTEXITCODE -eq 0) {
                try {
                    $secrets = $result | ConvertFrom-Json
                    $clientSecret = $secrets."DocumentManagement:ClientSecret"
                    
                    if ($clientSecret) {
                        if ($ShowValue) {
                            Write-Host "✅ Client Secret: $clientSecret" -ForegroundColor Green
                        } else {
                            $maskedSecret = $clientSecret.Substring(0, [Math]::Min(8, $clientSecret.Length)) + "..." + $clientSecret.Substring([Math]::Max(0, $clientSecret.Length - 4))
                            Write-Host "✅ Client Secret: $maskedSecret" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "⚠️  No Document Management client secret found" -ForegroundColor Yellow
                        Write-Host "   Run with -Action Set to configure it" -ForegroundColor Gray
                    }
                } catch {
                    Write-Error "❌ Failed to parse user secrets: $_"
                }
            } else {
                Write-Error "❌ Failed to get user secrets: $result"
            }
        }
        
        "List" {
            Write-Host "📋 Listing All User Secrets" -ForegroundColor Yellow
            Write-Host ""
            
            $result = dotnet user-secrets list 2>&1
            if ($LASTEXITCODE -eq 0) {
                if ($result -match "No secrets configured") {
                    Write-Host "ℹ️  No user secrets configured" -ForegroundColor Blue
                } else {
                    if ($ShowValue) {
                        Write-Host $result -ForegroundColor White
                    } else {
                        # Mask the values for security
                        $lines = $result -split "`n"
                        foreach ($line in $lines) {
                            if ($line -match "^(.+?)\s*=\s*(.+)$") {
                                $key = $matches[1]
                                $value = $matches[2]
                                $maskedValue = $value.Substring(0, [Math]::Min(8, $value.Length)) + "..." + $value.Substring([Math]::Max(0, $value.Length - 4))
                                Write-Host "$key = $maskedValue" -ForegroundColor White
                            } else {
                                Write-Host $line -ForegroundColor White
                            }
                        }
                    }
                }
            } else {
                Write-Error "❌ Failed to list user secrets: $result"
            }
        }
        
        "Clear" {
            Write-Host "🗑️  Clearing All User Secrets" -ForegroundColor Red
            Write-Host ""
            
            $confirmation = Read-Host "Are you sure you want to clear all user secrets? (y/N)"
            if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
                $result = dotnet user-secrets clear 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ All user secrets cleared successfully!" -ForegroundColor Green
                } else {
                    Write-Error "❌ Failed to clear user secrets: $result"
                }
            } else {
                Write-Host "❌ Operation cancelled" -ForegroundColor Yellow
            }
        }
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Blue
switch ($Action) {
    "Set" {
        Write-Host "   1. Restart IdentityServer to use the new secret:" -ForegroundColor White
        Write-Host "      docker-compose restart identityserver" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   2. Test the configuration:" -ForegroundColor White
        Write-Host "      .\scripts\test-doc-mgmt-client.ps1 -SkipCertificateCheck" -ForegroundColor Yellow
    }
    "Get" {
        Write-Host "   • Use -ShowValue to see the actual secret (be careful!)" -ForegroundColor White
        Write-Host "   • Run with -Action Set to update the secret" -ForegroundColor White
    }
    "List" {
        Write-Host "   • Use -ShowValue to see actual values (be careful!)" -ForegroundColor White
        Write-Host "   • Run with -Action Set to add the Document Management secret" -ForegroundColor White
    }
    "Clear" {
        Write-Host "   • Run with -Action Set to configure secrets again" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "✨ User Secrets management completed!" -ForegroundColor Green