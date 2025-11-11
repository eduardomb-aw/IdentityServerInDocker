#!/bin/bash
# Bash script to create development certificates for HTTPS

echo "Creating development certificates for Identity Server in Docker..."

# Create certs directory if it doesn't exist
mkdir -p ./certs

# Generate Identity Server certificate
echo "Generating Identity Server certificate..."
dotnet dev-certs https -ep ./certs/identityserver.pfx -p password --trust

# Generate Admin UI certificate
echo "Generating Admin UI certificate..."
dotnet dev-certs https -ep ./certs/adminui.pfx -p password

echo "Certificates created successfully!"
echo "Files created:"
echo "- ./certs/identityserver.pfx"
echo "- ./certs/adminui.pfx"

echo -e "\nIMPORTANT: These certificates are for development only!"
echo "Password for certificates: password"