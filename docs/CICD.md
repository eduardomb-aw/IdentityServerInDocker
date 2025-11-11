# CI/CD Pipeline Documentation

## Overview

This project includes comprehensive CI/CD pipelines using GitHub Actions to build, test, and publish Docker images to GitHub Container Registry (GHCR).

## Pipeline Features

### 🚀 Automated Docker Image Building
- **Multi-architecture builds**: Both `linux/amd64` and `linux/arm64` platforms
- **Separate images**: IdentityServer and AdminUI built as independent images
- **Registry**: Images published to GitHub Container Registry (ghcr.io)
- **Caching**: Docker layer caching for faster builds

### 📋 Automated Testing
- **Playwright tests**: Full end-to-end testing on pull requests
- **Multi-browser support**: Chrome, Firefox, Safari, Edge, Mobile browsers
- **Health checks**: Services verified before test execution
- **Test reports**: Playwright HTML reports uploaded as artifacts

### 🏷️ Smart Versioning
- **Branch builds**: `main` and `develop` branches get tagged with branch name
- **Pull requests**: Tagged with PR number
- **Semantic versioning**: Git tags like `v1.2.3` create proper semver tags
- **Latest tag**: Main branch builds also tagged as `latest`

## Workflow Structure

### Build Jobs
1. **build-identityserver**: Builds and pushes IdentityServer image
2. **build-adminui**: Builds and pushes AdminUI image  
3. **test**: Runs comprehensive Playwright tests (PR only)

### Trigger Events
- **Push to main/develop**: Builds and publishes images
- **Git tags (v*)**: Creates versioned releases
- **Pull requests**: Builds images and runs tests (no publishing)

## Published Images

### IdentityServer Image
```bash
docker pull ghcr.io/eduardomb-aw/identityserverindocker-identityserver:latest
```

### AdminUI Image  
```bash
docker pull ghcr.io/eduardomb-aw/identityserverindocker-adminui:latest
```

## Using Published Images

### Production Deployment
Use the production docker-compose file:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Custom Deployment
```yaml
services:
  identityserver:
    image: ghcr.io/eduardomb-aw/identityserverindocker-identityserver:latest
    ports:
      - "5000:5000"
      - "5001:5001"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production

  adminui:
    image: ghcr.io/eduardomb-aw/identityserverindocker-adminui:latest
    ports:
      - "5002:5002" 
      - "5003:5003"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - IdentityServerSettings__BaseUrl=https://identityserver:5001
```

## Health Checks

Both services include health check endpoints:

### IdentityServer
- **Basic**: `GET /health` - Returns 200 OK when healthy
- **Detailed**: Check IdentityServer4 status and configuration

### AdminUI  
- **Basic**: `GET /health` - Returns 200 OK when healthy
- **Detailed**: `GET /health/detailed` - JSON with service info and IdentityServer connectivity

## Local Development vs Production

### Development (docker-compose.yml)
- Uses local Dockerfiles to build images
- Mount volumes for development certificates
- Development environment variables

### Production (docker-compose.prod.yml)  
- Uses published GHCR images
- Production-ready configuration
- Health checks and restart policies
- Proper networking and dependencies

## Pipeline Monitoring

### GitHub Actions
- View workflow runs: `https://github.com/eduardomb-aw/IdentityServerInDocker/actions`
- Check build status and logs
- Download test artifacts

### Container Registry
- View published images: `https://github.com/eduardomb-aw/IdentityServerInDocker/pkgs/container/identityserverindocker-identityserver`
- Check image tags and sizes
- Pull statistics and usage

## Troubleshooting

### Build Failures
1. Check workflow logs in GitHub Actions
2. Verify Dockerfile syntax and dependencies
3. Check multi-architecture build compatibility

### Test Failures  
1. Review Playwright test reports in artifacts
2. Check service health endpoints
3. Verify container networking and timing

### Image Pull Issues
1. Ensure proper authentication to GHCR
2. Check image tags and availability
3. Verify network connectivity to ghcr.io

## Security Considerations

### Container Registry Access
- Images are public by default
- Private repositories require authentication
- Use GitHub tokens for CI/CD access

### Production Deployment
- Use proper SSL certificates (not development certs)
- Configure secure secrets management
- Implement proper network security
- Regular security updates of base images