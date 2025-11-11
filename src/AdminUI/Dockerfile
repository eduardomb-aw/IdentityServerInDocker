FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5002
EXPOSE 5003

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/AdminUI/AdminUI.csproj", "src/AdminUI/"]
RUN dotnet restore "src/AdminUI/AdminUI.csproj"
COPY . .
WORKDIR "/src/src/AdminUI"
RUN dotnet build "AdminUI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AdminUI.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Create logs directory
RUN mkdir -p /app/logs

# Set environment variables
ENV ASPNETCORE_URLS=https://+:5003;http://+:5002
ENV ASPNETCORE_HTTPS_PORT=5003

ENTRYPOINT ["dotnet", "AdminUI.dll"]