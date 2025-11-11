# IdentityServer4 + AdminUI Docker Setup

[![Build and Push Docker Images](https://github.com/eduardomb-aw/IdentityServerInDocker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/eduardomb-aw/IdentityServerInDocker/actions/workflows/docker-build.yml)

A complete containerized solution featuring **IdentityServer4** as an OAuth 2.0/OpenID Connect provider and a custom **AdminUI** for managing clients, scopes, and resources. Both services run in Docker containers and are accessible from the host machine.

## 🚀 Quick Start

### Option 1: Docker (Recommended)

**Prerequisites:**
- Docker Desktop
- PowerShell 7+ (recommended)

1. **Start with Docker:**
   ```powershell
   .\scripts\start-docker.ps1
   ```

2. **Test the services:**
   ```powershell
   .\scripts\test-auth-flows.ps1
   ```

3. **Access the services:**
   - **IdentityServer (HTTP)**: http://localhost:5000
   - **IdentityServer (HTTPS)**: https://localhost:5001
   - **Admin UI (HTTP)**: http://localhost:5002
   - **Admin UI (HTTPS)**: https://localhost:5003
   - **Discovery Document**: https://localhost:5001/.well-known/openid-configuration

4. **Stop when done:**
   ```powershell
   .\scripts\stop-docker.ps1
   ```

### Option 2: Local Development

**Prerequisites:**
- .NET 8.0 SDK
- PowerShell 7+ (recommended)

1. **Start the IdentityServer:**
   ```powershell
   .\scripts\start-identityserver.ps1
   ```

2. **Test the authentication flows:**
   ```powershell
   .\scripts\test-auth-flows.ps1
   ```

3. **Access the endpoints:**
   - **HTTP**: http://localhost:5000
   - **HTTPS**: https://localhost:5001
   - **Discovery Document**: https://localhost:5001/.well-known/openid-configuration

4. **Start the AdminUI (optional):**
   ```powershell
   .\scripts\start-adminui.ps1
   ```
   - **Admin UI**: https://localhost:5003

## 📋 Project Structure

```
IdentityServerInDocker/
├── src/
│   ├── IdentityServer/           # Main IdentityServer4 application
│   │   ├── Program.cs            # Application startup and configuration
│   │   ├── Configuration/        # OAuth/OIDC configuration
│   │   │   └── Config.cs         # Clients, scopes, and resources
│   │   └── Pages/                # Razor pages for UI
│   └── AdminUI/                  # Admin interface (future)
├── scripts/                      # PowerShell automation scripts
│   ├── start-identityserver.ps1  # Start the server in development
│   ├── test-auth-flows.ps1       # Test OAuth flows
│   └── test-endpoints.ps1        # Basic endpoint tests
├── docker/                       # Docker configuration files
└── docs/                         # Additional documentation
```

## 🔐 Authentication Flows

This IdentityServer4 instance supports the following OAuth 2.0 and OpenID Connect flows:

### 1. Client Credentials Flow (Machine-to-Machine)
- **Use Case**: Service-to-service authentication
- **Client ID**: `test-client`
- **Client Secret**: `secret`
- **Scopes**: `api1`

**Example Request:**
```powershell
$body = @{
    grant_type = 'client_credentials'
    client_id = 'test-client'  
    client_secret = 'secret'
    scope = 'api1'
}
$response = Invoke-RestMethod -Uri 'https://localhost:5001/connect/token' -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded' -SkipCertificateCheck
```

### 2. Authorization Code Flow (Interactive)
- **Use Case**: Web applications with user login
- **Client ID**: `web-client`
- **Client Secret**: `secret`
- **Scopes**: `openid`, `profile`, `api1`
- **Redirect URI**: `https://localhost:5002/signin-oidc`

**Example Authorization URL:**
```
https://localhost:5001/connect/authorize?client_id=web-client&response_type=code&scope=openid%20profile%20api1&redirect_uri=https://localhost:5002/signin-oidc&state=abc123
```

## 🔑 Endpoints

### Discovery Endpoints
- **Discovery Document**: `/.well-known/openid-configuration`
- **JWKS (Public Keys)**: `/.well-known/openid-configuration/jwks`

### OAuth 2.0 / OpenID Connect Endpoints
- **Authorization**: `/connect/authorize`
- **Token**: `/connect/token`
- **UserInfo**: `/connect/userinfo`
- **End Session**: `/connect/endsession`
- **Check Session**: `/connect/checksession`
- **Revocation**: `/connect/revocation`
- **Introspection**: `/connect/introspect`

## 🧪 Testing

### Automated Testing
Run the comprehensive test suite:
```powershell
.\scripts\test-auth-flows.ps1
```

### Manual Testing

#### Test Discovery Document
```powershell
Invoke-RestMethod -Uri "https://localhost:5001/.well-known/openid-configuration" -SkipCertificateCheck
```

#### Test Client Credentials Flow
```powershell
$body = @{
    grant_type = 'client_credentials'
    client_id = 'test-client'
    client_secret = 'secret'
    scope = 'api1'
}
$token = Invoke-RestMethod -Uri 'https://localhost:5001/connect/token' -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded' -SkipCertificateCheck
Write-Host "Access Token: $($token.access_token)"
```

#### Test JWKS Endpoint
```powershell
Invoke-RestMethod -Uri "https://localhost:5001/.well-known/openid-configuration/jwks" -SkipCertificateCheck
```

## ⚙️ Configuration

### Pre-configured Clients

#### Machine-to-Machine Client
```csharp
new Client
{
    ClientId = "test-client",
    AllowedGrantTypes = GrantTypes.ClientCredentials,
    ClientSecrets = { new Secret("secret".Sha256()) },
    AllowedScopes = { "api1" }
}
```

#### Interactive Web Client
```csharp
new Client
{
    ClientId = "web-client",
    AllowedGrantTypes = GrantTypes.Code,
    ClientSecrets = { new Secret("secret".Sha256()) },
    RedirectUris = { "https://localhost:5002/signin-oidc" },
    PostLogoutRedirectUris = { "https://localhost:5002/signout-callback-oidc" },
    AllowedScopes = { "openid", "profile", "api1" }
}
```

### Pre-configured Resources

#### Identity Resources
- `openid` - Subject identifier
- `profile` - User profile information

#### API Scopes
- `api1` - Access to API #1

## 🐳 Docker Deployment

### Option 1: Use Published Images (Recommended)

#### Quick Production Deployment
```powershell
# Deploy using published images from GitHub Container Registry
.\scripts\deploy.ps1 -Mode prod -Pull
```

#### Manual Deployment
```bash
# Pull the latest images
docker pull ghcr.io/eduardomb-aw/identityserverindocker-identityserver:latest
docker pull ghcr.io/eduardomb-aw/identityserverindocker-adminui:latest

# Run with production compose file
docker-compose -f docker-compose.prod.yml up -d
```

### Option 2: Build Locally

#### Building the Containers
```bash
# Build both services
docker-compose build

# Or build individually
docker build -t identityserver4-app -f src/IdentityServer/Dockerfile .
docker build -t adminui-app -f src/AdminUI/Dockerfile .
```

#### Running with Docker Compose
```bash
# Development mode (builds from source)
docker-compose up -d

# Production mode (uses published images)  
docker-compose -f docker-compose.prod.yml up -d
```

## 🚀 CI/CD Pipeline

### Automated Builds

This project includes comprehensive GitHub Actions workflows that automatically:

- ✅ **Build multi-architecture Docker images** (linux/amd64, linux/arm64)
- ✅ **Publish to GitHub Container Registry** (ghcr.io)
- ✅ **Run comprehensive Playwright tests** on pull requests
- ✅ **Support semantic versioning** via Git tags

### Published Images

```bash
# IdentityServer image
ghcr.io/eduardomb-aw/identityserverindocker-identityserver:latest

# AdminUI image  
ghcr.io/eduardomb-aw/identityserverindocker-adminui:latest
```

### Deployment Scripts

#### Quick Deployment
```powershell
# Deploy latest production images
.\scripts\deploy.ps1 -Mode prod -Pull

# Deploy specific version
.\scripts\deploy.ps1 -Mode prod -Tag v1.2.3 -Pull

# Clean up resources
.\scripts\deploy.ps1 -Clean
```

#### Health Checks
```powershell
# Check service health
Invoke-WebRequest https://localhost:5001/health -SkipCertificateCheck
Invoke-WebRequest https://localhost:5003/health -SkipCertificateCheck
```

### 📋 Pipeline Features

- **Automated Testing**: Full Playwright test suite runs on every PR
- **Multi-platform Builds**: Support for AMD64 and ARM64 architectures  
- **Smart Tagging**: Automatic versioning based on Git tags and branches
- **Security Scanning**: Container vulnerability analysis
- **Health Monitoring**: Built-in health check endpoints

For detailed CI/CD documentation, see [docs/CICD.md](docs/CICD.md).

## 🔒 Security Considerations

### Development vs Production

**Development Settings (Current):**
- Uses developer signing credentials (auto-generated)
- HTTP redirects enabled
- CORS policy allows any origin
- Self-signed certificates accepted

**Production Recommendations:**  
- Use proper signing certificates
- Configure specific CORS origins
- Use HTTPS only
- Implement proper certificate validation
- Use persistent data stores
- Enable rate limiting

## ⚠️ Security Notice

**This configuration is for development purposes only.** Before deploying to production, ensure proper security measures are implemented.