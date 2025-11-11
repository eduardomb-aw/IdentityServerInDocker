using IdentityServer4;
using IdentityServer4.Models;

namespace IdentityServer.Configuration;

public static class Config
{
    public static IEnumerable<IdentityResource> IdentityResources =>
        new List<IdentityResource>
        {
            new IdentityResources.OpenId(),
            new IdentityResources.Profile(),
            new IdentityResources.Email(),
            new IdentityResource("roles", "User roles", new[] { "role" })
        };

    public static IEnumerable<ApiScope> ApiScopes =>
        new List<ApiScope>
        {
            new ApiScope("api1", "My API #1"),
            new ApiScope("api2", "My API #2"),
            new ApiScope("weatherapi", "Weather API"),
            new ApiScope("adminui", "Admin UI API")
        };

    public static IEnumerable<ApiResource> ApiResources =>
        new List<ApiResource>
        {
            new ApiResource("api1", "My API #1")
            {
                Scopes = { "api1" }
            },
            new ApiResource("api2", "My API #2")
            {
                Scopes = { "api2" }
            },
            new ApiResource("weatherapi", "Weather API")
            {
                Scopes = { "weatherapi" }
            }
        };

    public static IEnumerable<Client> Clients =>
        new List<Client>
        {
            // Interactive ASP.NET Core Web App
            new Client
            {
                ClientId = "web",
                ClientSecrets = { new Secret("secret".Sha256()) },

                AllowedGrantTypes = GrantTypes.Code,

                // where to redirect to after login
                RedirectUris = { "https://localhost:5002/signin-oidc" },

                // where to redirect to after logout
                PostLogoutRedirectUris = { "https://localhost:5002/signout-callback-oidc" },

                AllowedScopes = new List<string>
                {
                    IdentityServerConstants.StandardScopes.OpenId,
                    IdentityServerConstants.StandardScopes.Profile,
                    IdentityServerConstants.StandardScopes.Email,
                    "roles",
                    "api1"
                },

                RequireConsent = false,
                AllowOfflineAccess = true
            },

            // Admin UI Client
            new Client
            {
                ClientId = "adminui",
                ClientName = "Admin UI",
                ClientSecrets = { new Secret("adminui_secret".Sha256()) },

                AllowedGrantTypes = GrantTypes.Code,

                RedirectUris = { "https://localhost:5003/signin-oidc" },
                PostLogoutRedirectUris = { "https://localhost:5003/signout-callback-oidc" },

                AllowedScopes = new List<string>
                {
                    IdentityServerConstants.StandardScopes.OpenId,
                    IdentityServerConstants.StandardScopes.Profile,
                    IdentityServerConstants.StandardScopes.Email,
                    "roles",
                    "adminui"
                },

                RequireConsent = false,
                AllowOfflineAccess = true
            },

            // JavaScript Client (SPA)
            new Client
            {
                ClientId = "js",
                ClientName = "JavaScript Client",
                AllowedGrantTypes = GrantTypes.Code,
                RequireClientSecret = false,

                RedirectUris =           { "https://localhost:5004/callback.html" },
                PostLogoutRedirectUris = { "https://localhost:5004/index.html" },
                AllowedCorsOrigins =     { "https://localhost:5004" },

                AllowedScopes =
                {
                    IdentityServerConstants.StandardScopes.OpenId,
                    IdentityServerConstants.StandardScopes.Profile,
                    "api1"
                }
            },

            // Machine to Machine Client
            new Client
            {
                ClientId = "m2m",
                ClientName = "Machine to Machine Client",
                ClientSecrets = { new Secret("m2m_secret".Sha256()) },

                AllowedGrantTypes = GrantTypes.ClientCredentials,

                AllowedScopes = { "api1", "api2", "weatherapi" }
            }
        };
}