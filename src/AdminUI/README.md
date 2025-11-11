# AdminUI

Simple web-based administration interface for IdentityServer4 configuration and monitoring.

## Overview

This AdminUI provides a basic web interface to view and monitor your IdentityServer4 instance. It connects to IdentityServer4 via HTTP APIs and discovery endpoints.

## Features

- ✅ **Configuration Overview** - View clients, API scopes, and identity resources
- ✅ **Server Status** - Monitor IdentityServer4 health and connectivity
- ✅ **Discovery Information** - Display OpenID Connect discovery document details
- ✅ **Authentication** - Secured with OpenID Connect authentication

## Configuration

### Authentication

The AdminUI authenticates against IdentityServer4 using OpenID Connect:

- **Client ID**: `adminui-client`
- **Client Secret**: `adminui-secret`
- **Scopes**: `openid`, `profile`, `api1`
- **Flow**: Authorization Code with PKCE

### Connection

The AdminUI connects to IdentityServer4 via:
- **Local Development**: `https://localhost:5001`
- **Docker**: `http://identityserver:5000` (internal container network)

## Access

### Local Development
```powershell
.\scripts\start-adminui.ps1
```
- **HTTPS**: https://localhost:5003
- **HTTP**: http://localhost:5002

### Docker
```powershell
.\scripts\start-docker.ps1
```
- **HTTPS**: https://localhost:5003
- **HTTP**: http://localhost:5002
- **Health**: http://localhost:5002/health

## Project Structure

```
AdminUI/
├── Controllers/
│   └── HomeController.cs       # Main dashboard controller
├── Services/
│   └── IdentityServerAdminService.cs  # HTTP client for IdentityServer4
├── Views/                      # Razor views (auto-generated)
├── Program.cs                  # Application startup
└── AdminUI.csproj             # Project dependencies
```

## Development

### Prerequisites
- .NET 8.0 SDK
- IdentityServer4 instance running

### Dependencies
- `Microsoft.AspNetCore.Authentication.OpenIdConnect` - OIDC authentication
- `Serilog.AspNetCore` - Structured logging

### Build
```powershell
dotnet build src/AdminUI/AdminUI.csproj
```

### Run
```powershell
dotnet run --project src/AdminUI/AdminUI.csproj
```

## Extending

This is a minimal AdminUI implementation. You can extend it by:

1. **Adding more views** - Create additional Razor pages for detailed management
2. **Enhanced services** - Extend `IdentityServerAdminService` with more API calls
3. **User management** - Add user administration features
4. **Logging dashboard** - Display IdentityServer4 logs and events
5. **Configuration editing** - Add forms to modify clients and resources (requires IdentityServer4 API)