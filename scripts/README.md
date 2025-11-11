# PowerShell Scripts

This directory contains automation scripts for managing the IdentityServer4 development environment.

## Scripts

### `start-identityserver.ps1`
Starts the IdentityServer4 application in development mode.

**Usage:**
```powershell
.\start-identityserver.ps1
```

**What it does:**
- Sets `ASPNETCORE_ENVIRONMENT=Development`
- Navigates to the IdentityServer project directory
- Starts the server with `dotnet run`
- Server will be available at:
  - HTTP: http://localhost:5000
  - HTTPS: https://localhost:5001

### `start-adminui.ps1`
Starts the AdminUI application for managing IdentityServer4.

**Usage:**
```powershell
.\start-adminui.ps1
```

**What it does:**
- Sets up development environment for AdminUI
- Builds and starts the AdminUI application
- AdminUI will be available at:
  - HTTP: http://localhost:5002
  - HTTPS: https://localhost:5003
- **Note:** Requires IdentityServer to be running first

### `test-auth-flows.ps1`
Comprehensive test suite for OAuth 2.0 and OpenID Connect authentication flows.

**Usage:**
```powershell
# Test with default settings (localhost:5001)
.\test-auth-flows.ps1

# Test with custom base URL
.\test-auth-flows.ps1 -BaseUrl "https://myserver:5001"

# Test without skipping certificate validation
.\test-auth-flows.ps1 -SkipCertificateCheck:$false
```

**Tests performed:**
- ✅ Discovery document retrieval
- ✅ JWKS endpoint accessibility
- ✅ Client Credentials flow (machine-to-machine)
- ✅ Authorization Code flow setup (interactive)
- ✅ Error handling (invalid clients, invalid scopes)
- ✅ JWT token validation and claims inspection

### `test-endpoints.ps1`
Basic endpoint connectivity tests.

**Usage:**
```powershell
.\test-endpoints.ps1
```

**Tests performed:**
- ✅ HTTP base URL (port 5000)
- ✅ HTTPS base URL (port 5001)  
- ✅ Discovery endpoints (both HTTP and HTTPS)

### `start-docker.ps1`
Starts the IdentityServer and AdminUI using Docker Compose.

**Usage:**
```powershell
# Start containers normally
.\start-docker.ps1

# Force rebuild and run in background
.\start-docker.ps1 -Build -Detach
```

**What it does:**
- ✅ Validates Docker is running
- 🔨 Optionally rebuilds Docker images
- 🚀 Starts containers via docker-compose
- 📊 Displays service URLs and next steps

### `stop-docker.ps1`
Stops and cleans up Docker containers and resources.

**Usage:**
```powershell
# Just stop containers
.\stop-docker.ps1

# Stop and remove everything (with confirmation)
.\stop-docker.ps1 -RemoveImages -RemoveVolumes

# Force removal without prompts
.\stop-docker.ps1 -RemoveImages -RemoveVolumes -Force
```

**What it does:**
- 🛑 Stops and removes containers
- 🗑️ Optionally removes Docker images
- 🗑️ Optionally removes Docker volumes (data)
- 📊 Shows cleanup status

### `cleanup.ps1`
Cleans up temporary files and build artifacts from the project.

**Usage:**
```powershell
# Basic cleanup
.\cleanup.ps1

# Deep clean including NuGet cache
.\cleanup.ps1 -Deep
```

**What it does:**
- 🛑 Stops lingering dotnet processes
- 🧹 Removes build artifacts (bin/obj folders)
- 🗑️ Removes backup files (.bak, .backup, .tmp, etc.)
- 🗂️ Optionally removes log files
- 🔥 Deep clean: NuGet cache and temp files

## Prerequisites

- PowerShell 7+ (recommended) or Windows PowerShell 5.1+
- .NET 8.0 SDK
- IdentityServer4 application running (for test scripts)

## Examples

### Quick Development Workflow

1. **Start the server:**
   ```powershell
   .\scripts\start-identityserver.ps1
   ```

2. **In another terminal, run tests:**
   ```powershell
   .\scripts\test-auth-flows.ps1
   ```

### Automated Testing in CI/CD

```powershell
# Start server in background
Start-Process powershell -ArgumentList ".\scripts\start-identityserver.ps1" -WindowStyle Hidden

# Wait for server to start
Start-Sleep -Seconds 10

# Run tests
$testResult = .\scripts\test-auth-flows.ps1

# Process results...
```

## Troubleshooting

### Script Execution Policy
If you get execution policy errors:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Port Already in Use
If ports 5000/5001 are in use:
```powershell
# Find processes using the ports
Get-NetTCPConnection -LocalPort 5000,5001 | Select-Object LocalPort, OwningProcess

# Kill dotnet processes
Get-Process -Name dotnet | Stop-Process -Force
```

### Certificate Issues
For development with self-signed certificates:
```powershell
# Trust the development certificate
dotnet dev-certs https --trust
```