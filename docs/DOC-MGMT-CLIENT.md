# Document Management Client Configuration

This directory contains scripts to configure and test the Document Management OAuth 2.0 client in IdentityServer4.

## 🚀 Quick Setup

### 1. Configure the Document Management Client

Run the setup script to add the client configuration to IdentityServer:

```powershell
.\scripts\setup-doc-mgmt-client.ps1 -BackupOriginal
```

This will:
- ✅ Add required API scopes for AM Link services
- ✅ Configure the `doc-mgmt-client` client with Authorization Code flow
- ✅ Create a backup of the original Program.cs

### 2. Set the Client Secret

Configure the actual client secret securely using .NET User Secrets (recommended):

```powershell
# Set the client secret using User Secrets (recommended)
.\scripts\manage-user-secrets.ps1 -Action Set

# Alternative: Use environment variable (legacy method)
$env:DOC_MGMT_CLIENT_SECRET = "your-actual-secret-here"
.\scripts\configure-doc-mgmt-secret.ps1 -EnvironmentVariable
```

> **💡 Why User Secrets?**
> - Secrets are stored in your local user profile, never in the repository
> - No risk of accidentally committing secrets to Git
> - Secure, encrypted storage on your local machine
> - Easy to manage with the .NET CLI

### 3. Restart IdentityServer

Apply the configuration changes:

```powershell
docker-compose restart identityserver
```

### 4. Test the Configuration

Verify everything works:

```powershell
.\scripts\test-doc-mgmt-client.ps1 -SkipCertificateCheck
```

## 📋 Client Configuration

| Setting | Value |
|---------|-------|
| **Client ID** | `doc-mgmt-client` |
| **Grant Type** | Authorization Code |
| **Redirect URI** | `http://localhost:1180/callback` |
| **Post Logout URI** | `http://localhost:1180/logout` |
| **Client Secret** | Configured via `configure-doc-mgmt-secret.ps1` |

## 🔑 API Scopes

The following scopes are added and available for the Document Management client:

- `openid` - OpenID Connect identifier
- `profile` - User profile information  
- `amlink-maintenance-api` - AM Link Maintenance API access
- `amlink-submission-api` - AM Link Submission API access
- `amlink-policy-api` - AM Link Policy API access
- `amlink-doc-api` - AM Link Document API access
- `amwins-graphadapter-api` - AM Wins Graph Adapter API access

## 🧪 Testing & Demo

### Test Configuration
```powershell
# Test client configuration and endpoints
.\scripts\test-doc-mgmt-client.ps1 -SkipCertificateCheck
```

### OAuth Flow Demo
```powershell
# Show OAuth flow with code examples
.\scripts\demo-doc-mgmt-oauth.ps1

# Interactive OAuth flow test
.\scripts\demo-doc-mgmt-oauth.ps1 -Interactive
```

## 🔗 OAuth 2.0 Integration Example

### Authorization URL

Redirect users to:

```
https://localhost:5001/connect/authorize?
  client_id=doc-mgmt-client&
  response_type=code&
  scope=openid%20profile%20amlink-maintenance-api%20amlink-submission-api%20amlink-policy-api%20amlink-doc-api%20amwins-graphadapter-api&
  redirect_uri=http%3A%2F%2Flocalhost%3A1180%2Fcallback&
  state=YOUR_STATE_VALUE&
  nonce=YOUR_NONCE_VALUE
```

### Token Exchange

After receiving the authorization code, exchange it for tokens:

```http
POST https://localhost:5001/connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
code=AUTHORIZATION_CODE&
client_id=doc-mgmt-client&
client_secret=YOUR_CLIENT_SECRET&
redirect_uri=http://localhost:1180/callback
```

### Access Token Usage

Use the access token in API requests:

```http
GET https://your-api.com/endpoint
Authorization: Bearer ACCESS_TOKEN
```

## 🔒 Security Features

- **User Secrets**: Secure local storage using .NET User Secrets
- **Refresh Tokens**: Enabled with 15-day sliding expiration
- **PKCE Support**: Recommended for additional security
- **State Validation**: Prevents CSRF attacks
- **No Hardcoded Secrets**: Client secrets never committed to repository

### 🔐 User Secrets Management

The project uses .NET User Secrets for secure local secret storage:

```powershell
# Set your client secret
.\scripts\manage-user-secrets.ps1 -Action Set

# View stored secrets (masked)
.\scripts\manage-user-secrets.ps1 -Action Get

# List all user secrets
.\scripts\manage-user-secrets.ps1 -Action List

# Clear all secrets
.\scripts\manage-user-secrets.ps1 -Action Clear
```

**User Secrets Benefits:**
- ✅ Never committed to Git repository
- ✅ Stored securely in your user profile
- ✅ Available only to you on this machine
- ✅ Automatically loaded by IdentityServer
- ✅ No environment variables needed

## 🛠️ Script Reference

| Script | Purpose |
|--------|---------|
| `setup-doc-mgmt-client.ps1` | Configures client in IdentityServer Program.cs |
| `manage-user-secrets.ps1` | Manages .NET User Secrets (recommended) |
| `configure-doc-mgmt-secret.ps1` | Sets client secret in Program.cs (legacy) |
| `test-doc-mgmt-client.ps1` | Validates client configuration |
| `demo-doc-mgmt-oauth.ps1` | OAuth integration examples and testing |

## 🔄 Production Considerations

For production deployments:

1. **Use HTTPS**: Update redirect URIs to use HTTPS
2. **Azure Key Vault**: Store client secrets in Azure Key Vault
3. **Environment Variables**: Use secure environment variable injection
4. **Certificate Validation**: Remove `SkipCertificateCheck` flags
5. **PKCE Implementation**: Add Proof Key for Code Exchange for enhanced security

## 🧹 Cleanup

To remove the Document Management client configuration:

```powershell
# Restore original Program.cs from backup
$backup = Get-ChildItem "src/IdentityServer/Program.cs.backup.*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($backup) {
    Copy-Item $backup.FullName "src/IdentityServer/Program.cs"
    Write-Host "Restored from backup: $($backup.Name)"
}

# Restart IdentityServer
docker-compose restart identityserver
```