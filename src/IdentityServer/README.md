# Identity Server Project

A complete Identity Server 4 setup with AdminUI running in Docker containers.

## Quick Start

1. **Prerequisites**
   - Docker Desktop
   - .NET 8.0 SDK (for certificate generation)

2. **Start the services**
   ```powershell
   .\scripts\start.ps1
   ```

3. **Access the applications**
   - Identity Server: https://localhost:5001
   - Admin UI: https://localhost:5003

## Architecture

The solution consists of three main components:

- **Identity Server**: Duende IdentityServer providing OAuth 2.0 and OpenID Connect
- **Admin UI**: Skoruba's IdentityServer Admin UI for managing configuration
- **SQL Server**: Database for storing Identity Server configuration and operational data

## Configuration

### Pre-configured Clients

| Client ID | Description | Redirect URI |
|-----------|-------------|--------------|
| `web` | Interactive web application | https://localhost:5002/signin-oidc |
| `adminui` | Admin UI application | https://localhost:5003/signin-oidc |
| `js` | JavaScript SPA | https://localhost:5004/callback.html |
| `m2m` | Machine-to-machine | N/A |

### Default Scopes

- `openid` - OpenID Connect identity
- `profile` - User profile information
- `email` - User email
- `roles` - User roles
- `api1` - Sample API scope
- `api2` - Sample API scope
- `weatherapi` - Weather API scope
- `adminui` - Admin UI API scope

## Development

### Project Structure

```
├── src/
│   ├── IdentityServer/      # Main Identity Server application
│   └── AdminUI/             # Admin UI application
├── docker/                  # Docker configuration
├── scripts/                 # Utility scripts
├── certs/                   # SSL certificates (generated)
├── logs/                    # Application logs
└── database/                # Database initialization scripts
```

### Scripts

- `scripts/start.ps1` - Build and start all services
- `scripts/stop.ps1` - Stop all services
- `scripts/create-dev-certs.ps1` - Generate development certificates

### Docker Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Reset everything (including data)
docker-compose down -v
```

## Network Configuration

The services are configured to be accessible from your host machine:

| Service | Internal Port | External Port | Protocol |
|---------|---------------|---------------|----------|
| Identity Server | 5001 | 5001 | HTTPS |
| Identity Server | 5000 | 5000 | HTTP |
| Admin UI | 5003 | 5003 | HTTPS |
| Admin UI | 5002 | 5002 | HTTP |
| SQL Server | 1433 | 1433 | TCP |

## Security Notes

- Development certificates are automatically generated
- Default SQL Server password: `YourStrong@Passw0rd`
- Client secrets are stored in configuration (change for production)
- HTTPS is enforced for all external communication

## Customization

### Adding New Clients

1. Edit `src/IdentityServer/Configuration/Config.cs`
2. Add your client configuration to the `Clients` property
3. Rebuild and restart the containers

### Adding New API Resources

1. Edit `src/IdentityServer/Configuration/Config.cs`
2. Add your API resource to the `ApiResources` property
3. Add corresponding scopes to `ApiScopes`
4. Rebuild and restart the containers

## Troubleshooting

### Common Issues

1. **Certificate errors**: Run `scripts/create-dev-certs.ps1` to regenerate certificates
2. **Database connection errors**: Ensure SQL Server container is running and healthy
3. **Port conflicts**: Check if ports 5001, 5003, or 1433 are already in use

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f identityserver
docker-compose logs -f adminui
docker-compose logs -f sqlserver
```

## Production Considerations

Before deploying to production:

1. Replace development certificates with proper SSL certificates
2. Change default passwords and secrets
3. Configure proper logging and monitoring
4. Set up proper backup strategies for the database
5. Review and harden security settings
6. Configure proper reverse proxy if needed