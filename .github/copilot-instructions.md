# GitHub Copilot Instructions for IdentityServerInDocker

## Project Overview
This is a containerized OAuth 2.0/OpenID Connect solution with two main services:
- **IdentityServer** (ports 5000/5001): IdentityServer4-based auth provider with in-memory stores
- **AdminUI** (ports 5002/5003): ASP.NET Core admin interface using HTTP client pattern (not EF)

**Key Architecture Decision**: AdminUI communicates with IdentityServer via HTTP APIs, not shared database.

## Development Patterns

### Container-Aware URL Binding
Both services use this pattern in `Program.cs`:
```csharp
if (builder.Environment.IsDevelopment() && Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true")
{
    builder.WebHost.UseUrls("http://+:5000", "https://+:5001"); // Listen on all interfaces
}
else {
    builder.WebHost.UseUrls("http://localhost:5000", "https://localhost:5001"); // Localhost only
}
```

### HTTP Client Service Pattern (AdminUI)
AdminUI uses HTTP clients instead of Entity Framework:
- Service interfaces in `AdminUI/Services/`
- HttpClient configured with `IdentityServerSettings__BaseUrl` 
- Certificate validation bypassed for dev: `ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true`

### In-Memory Configuration (IdentityServer)
Configuration methods at bottom of `src/IdentityServer/Program.cs`:
- `GetIdentityResources()` - OpenID/Profile scopes
- `GetApiScopes()` - API access scopes  
- `GetClients()` - Pre-configured OAuth clients

## Essential Workflows

### Quick Start (Most Common)
```powershell
.\scripts\start-docker.ps1    # Start containers
.\scripts\test-auth-flows.ps1 # Verify OAuth flows
.\scripts\stop-docker.ps1     # Clean shutdown
```

### Development & Testing
```powershell
.\scripts\deploy.ps1 -Mode dev              # Local development mode
.\scripts\deploy.ps1 -Mode prod -Pull       # Production with GHCR images
cd tests && npx playwright test             # Run E2E tests
.\scripts\Run-PlaywrightTests.ps1          # PowerShell wrapper for tests
```

### CI/CD Pipeline
- **GitHub Actions**: `.github/workflows/docker-build.yml`
- **Multi-arch builds**: linux/amd64 + linux/arm64
- **Published to**: `ghcr.io/eduardomb-aw/identityserverindocker-{identityserver|adminui}`
- **CI override**: Creates `docker-compose.ci.yml` for HTTP-only testing (no certificates)

## Project-Specific Conventions

### Certificate Management
- Development certs in `./certs/` (gitignored)
- CI uses HTTP-only via `docker-compose.ci.yml` override
- Scripts: `create-dev-certs.ps1` and `.sh` for cross-platform

### Service Communication
- **Container hostnames**: `identityserver` and `adminui` (not localhost)
- **AdminUI → IdentityServer**: Uses `IdentityServerOptions__BaseUrl` environment variable
- **Network**: Custom bridge network `identityserver-network`

### Testing Approach
- **Playwright E2E**: Multi-browser testing in `tests/`
- **Environment URLs**: Uses `IDENTITY_SERVER_URL` and `ADMIN_UI_URL` env vars for CI
- **Health checks**: Both services expose `/health` endpoints

### PowerShell Automation
Critical scripts in `scripts/`:
- `deploy.ps1` - Production deployment with health monitoring
- `start-docker.ps1` / `stop-docker.ps1` - Container lifecycle
- `test-auth-flows.ps1` - OAuth client credentials + authorization code flows

## Commit Message Style
- Keep commit messages short and concise
- Use imperative mood (e.g., "Add feature" not "Added feature")
- Focus on what changed, not why (details go in PR descriptions)

## Docker Configurations

### Development (`docker-compose.yml`)
- Builds from local Dockerfiles
- Certificate volume mounts from `./certs`
- Full HTTPS with self-signed certs

### Production (`docker-compose.prod.yml`) 
- Uses published GHCR images
- Proper health checks and restart policies
- Production environment variables

### CI Override Pattern
Creates temporary `docker-compose.ci.yml` that removes certificate requirements and uses HTTP-only for reliable testing.

## Issue Management
Uses GitHub Issues with labels:
- `priority: high/medium` - Urgency levels
- `bug/enhancement` - Issue types  
- `adminui/identityserver/testing` - Component areas
- Professional issue templates with acceptance criteria and technical details