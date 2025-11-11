using System.Text.Json;

namespace AdminUI.Services;

// Simple models for displaying configuration info
public class ClientInfo
{
    public string ClientId { get; set; } = string.Empty;
    public string ClientName { get; set; } = string.Empty;
    public List<string> AllowedGrantTypes { get; set; } = new();
    public List<string> AllowedScopes { get; set; } = new();
    public List<string> RedirectUris { get; set; } = new();
}

public class ApiScopeInfo
{
    public string Name { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class IdentityResourceInfo
{
    public string Name { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class DiscoveryInfo
{
    public string Issuer { get; set; } = string.Empty;
    public string AuthorizationEndpoint { get; set; } = string.Empty;
    public string TokenEndpoint { get; set; } = string.Empty;
    public string UserInfoEndpoint { get; set; } = string.Empty;
    public string JwksUri { get; set; } = string.Empty;
    public List<string> ScopesSupported { get; set; } = new();
    public List<string> ResponseTypesSupported { get; set; } = new();
}

public interface IIdentityServerAdminService
{
    Task<List<ClientInfo>> GetClientsAsync();
    Task<List<ApiScopeInfo>> GetApiScopesAsync();
    Task<List<IdentityResourceInfo>> GetIdentityResourcesAsync();
    Task<DiscoveryInfo?> GetDiscoveryInfoAsync();
}

public class IdentityServerAdminService : IIdentityServerAdminService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly string _identityServerBaseUrl;

    public IdentityServerAdminService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _identityServerBaseUrl = _configuration["IdentityServerOptions:BaseUrl"] ?? "https://localhost:5001";
    }

    public async Task<List<ClientInfo>> GetClientsAsync()
    {
        // Since we're using in-memory stores, return the known configured clients
        // In a real implementation, you might expose an API endpoint from IdentityServer
        return new List<ClientInfo>
        {
            new ClientInfo
            {
                ClientId = "test-client",
                ClientName = "Test Client (Machine to Machine)",
                AllowedGrantTypes = new() { "client_credentials" },
                AllowedScopes = new() { "api1" },
                RedirectUris = new()
            },
            new ClientInfo
            {
                ClientId = "web-client",
                ClientName = "Web Client (Interactive)",
                AllowedGrantTypes = new() { "authorization_code" },
                AllowedScopes = new() { "openid", "profile", "api1" },
                RedirectUris = new() { "https://localhost:7001/signin-oidc" }
            },
            new ClientInfo
            {
                ClientId = "adminui-client",
                ClientName = "Admin UI Client",
                AllowedGrantTypes = new() { "authorization_code" },
                AllowedScopes = new() { "openid", "profile", "api1" },
                RedirectUris = new() { "https://localhost:5003/signin-oidc" }
            }
        };
    }

    public async Task<List<ApiScopeInfo>> GetApiScopesAsync()
    {
        return new List<ApiScopeInfo>
        {
            new ApiScopeInfo
            {
                Name = "api1",
                DisplayName = "My API",
                Description = "Access to the main API"
            }
        };
    }

    public async Task<List<IdentityResourceInfo>> GetIdentityResourcesAsync()
    {
        return new List<IdentityResourceInfo>
        {
            new IdentityResourceInfo
            {
                Name = "openid",
                DisplayName = "OpenID",
                Description = "OpenID Connect identity information"
            },
            new IdentityResourceInfo
            {
                Name = "profile",
                DisplayName = "Profile",
                Description = "User profile information"
            }
        };
    }

    public async Task<DiscoveryInfo?> GetDiscoveryInfoAsync()
    {
        try
        {
            var discoveryUrl = $"{_identityServerBaseUrl}/.well-known/openid-configuration";
            var response = await _httpClient.GetAsync(discoveryUrl);
            
            if (response.IsSuccessStatusCode)
            {
                var json = await response.Content.ReadAsStringAsync();
                var discoveryDoc = JsonSerializer.Deserialize<JsonElement>(json);

                return new DiscoveryInfo
                {
                    Issuer = discoveryDoc.GetProperty("issuer").GetString() ?? "",
                    AuthorizationEndpoint = discoveryDoc.GetProperty("authorization_endpoint").GetString() ?? "",
                    TokenEndpoint = discoveryDoc.GetProperty("token_endpoint").GetString() ?? "",
                    UserInfoEndpoint = discoveryDoc.TryGetProperty("userinfo_endpoint", out var userInfoProp) ? userInfoProp.GetString() ?? "" : "",
                    JwksUri = discoveryDoc.GetProperty("jwks_uri").GetString() ?? "",
                    ScopesSupported = discoveryDoc.TryGetProperty("scopes_supported", out var scopesProp) ? 
                        scopesProp.EnumerateArray().Select(s => s.GetString() ?? "").ToList() : new(),
                    ResponseTypesSupported = discoveryDoc.TryGetProperty("response_types_supported", out var responseTypesProp) ? 
                        responseTypesProp.EnumerateArray().Select(s => s.GetString() ?? "").ToList() : new()
                };
            }
        }
        catch (Exception)
        {
            // Handle connection errors gracefully
        }

        return null;
    }
}