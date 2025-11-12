using Serilog;
using IdentityServer4.Models;
using IdentityServer4;
using IdentityServer4.Test;
using System.Security.Claims;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File("logs/identityserver.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    // Configure URLs explicitly - use + to listen on all interfaces for Docker
    if (builder.Environment.IsDevelopment() && Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true")
    {
        // Running in Docker container - listen on all interfaces
        builder.WebHost.UseUrls("http://+:5000", "https://+:5001");
    }
    else
    {
        // Running locally - listen on localhost only
        builder.WebHost.UseUrls("http://localhost:5000", "https://localhost:5001");
    }

    builder.Host.UseSerilog(Log.Logger);

    // Add services to the container
    builder.Services.AddRazorPages();
    builder.Services.AddControllersWithViews();
    builder.Services.AddHealthChecks();
    
    // Add anti-forgery token support
    builder.Services.AddAntiforgery(options =>
    {
        options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        options.Cookie.SameSite = SameSiteMode.Strict;
    });

    // Add IdentityServer4 with minimal required resources
    var testUsers = GetUsers();
    builder.Services.AddSingleton(new TestUserStore(testUsers));
    
    builder.Services.AddIdentityServer()
        .AddInMemoryIdentityResources(GetIdentityResources())
        .AddInMemoryApiScopes(GetApiScopes())
        .AddInMemoryClients(GetClients(builder.Configuration))
        .AddTestUsers(testUsers)
        .AddDeveloperSigningCredential();

    // Add CORS
    builder.Services.AddCors(options =>
    {
        options.AddDefaultPolicy(policy =>
        {
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        });
    });

    var app = builder.Build();

    // Configure the HTTP request pipeline
    if (!app.Environment.IsDevelopment())
    {
        app.UseExceptionHandler("/Error");
        app.UseHsts();
    }
    else
    {
        app.UseDeveloperExceptionPage();
    }

    app.UseHttpsRedirection();
    app.UseStaticFiles();
    app.UseRouting();
    
    app.UseIdentityServer();
    
    app.UseAuthorization();
    app.MapRazorPages();
    app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Home}/{action=Index}/{id?}");
    app.MapHealthChecks("/health");

    Log.Information("Starting IdentityServer4...");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "IdentityServer4 terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

static IEnumerable<IdentityServer4.Models.IdentityResource> GetIdentityResources()
{
    return new List<IdentityServer4.Models.IdentityResource>
    {
        new IdentityServer4.Models.IdentityResources.OpenId(),
        new IdentityServer4.Models.IdentityResources.Profile()
    };
}

static IEnumerable<IdentityServer4.Models.ApiScope> GetApiScopes()
{
    return new List<IdentityServer4.Models.ApiScope>
    {
        new IdentityServer4.Models.ApiScope("api1", "My API"),
                new IdentityServer4.Models.ApiScope("amlink-maintenance-api", "AM Link Maintenance API"),
        new IdentityServer4.Models.ApiScope("amlink-submission-api", "AM Link Submission API"),
        new IdentityServer4.Models.ApiScope("amlink-policy-api", "AM Link Policy API"),
        new IdentityServer4.Models.ApiScope("amlink-doc-api", "AM Link Document API"),
        new IdentityServer4.Models.ApiScope("amwins-graphadapter-api", "AM Wins Graph Adapter API"),
    };
}

static IEnumerable<Client> GetClients(IConfiguration configuration)
{
    // Get the Document Management client secret from User Secrets or fallback
    var docMgmtSecret = configuration["DocumentManagement:ClientSecret"] ?? "YOUR_CLIENT_SECRET_HERE";
    Log.Information("Loading Document Management client with secret: {SecretLength} characters", docMgmtSecret?.Length ?? 0);
    
    var clients = new List<Client>
    {
        // Machine to machine client
        new Client
        {
            ClientId = "test-client",
            AllowedGrantTypes = GrantTypes.ClientCredentials,
            ClientSecrets = { new Secret("secret".Sha256()) },
            AllowedScopes = { "api1" }
        },
        // Interactive client
        new Client
        {
            ClientId = "web-client",
            AllowedGrantTypes = GrantTypes.Code,
            ClientSecrets = { new Secret("secret".Sha256()) },
            RedirectUris = { "https://localhost:7001/signin-oidc" },
            PostLogoutRedirectUris = { "https://localhost:7001/signout-callback-oidc" },
            AllowedScopes = { "openid", "profile", "api1" }
        },
        // Admin UI client
        new Client
        {
            ClientId = "adminui-client",
            ClientName = "IdentityServer Admin UI",
            AllowedGrantTypes = GrantTypes.Code,
            ClientSecrets = { new Secret("adminui-secret".Sha256()) },
            RedirectUris = { "https://localhost:5003/signin-oidc" },
            PostLogoutRedirectUris = { "https://localhost:5003/signout-callback-oidc" },
            AllowedScopes = { "openid", "profile", "api1" },
            RequireConsent = false,
            AllowAccessTokensViaBrowser = true
        },
        // Document Management client
        new Client
        {
            ClientId = "doc-mgmt-client",
            ClientName = "Document Management System",
            AllowedGrantTypes = GrantTypes.CodeAndClientCredentials, // Allow both flows
            
            // Client secrets for secure communication - loaded from User Secrets
            ClientSecrets = { new Secret(docMgmtSecret.Sha256()) },
            
            // Redirect URIs for OAuth callback
            RedirectUris = { "http://localhost:1180/callback" },
            PostLogoutRedirectUris = { "http://localhost:1180/logout" },
            
            // Allowed scopes for AM Link APIs
            AllowedScopes = { 
                "openid", 
                "profile",
                "amlink-maintenance-api",
                "amlink-submission-api", 
                "amlink-policy-api",
                "amlink-doc-api",
                "amwins-graphadapter-api"
            },
            
            // OAuth settings
            RequireConsent = false,
            AllowAccessTokensViaBrowser = true,
            AllowOfflineAccess = true, // Enable refresh tokens
            RequirePkce = false, // Disable PKCE for testing (not recommended for production)
            
            // Token lifetimes (in seconds)
            AccessTokenLifetime = 3600, // 1 hour
            RefreshTokenUsage = TokenUsage.ReUse,
            RefreshTokenExpiration = TokenExpiration.Sliding,
            SlidingRefreshTokenLifetime = 1296000, // 15 days
        },
    };
    
    Log.Information("Loaded {ClientCount} clients: {ClientIds}", clients.Count, string.Join(", ", clients.Select(c => c.ClientId)));
    return clients;
}

static List<TestUser> GetUsers()
{
    // WARNING: This is for development/testing only!
    // In production, use proper user management with:
    // - Secure password hashing (bcrypt, Argon2, etc.)
    // - User database (Entity Framework, Identity, etc.)
    // - Account lockout and rate limiting
    // - Strong password policies
    
    return new List<TestUser>
    {
        new TestUser
        {
            SubjectId = "1",
            Username = "testuser",
            Password = "password", // TODO: Use hashed passwords in production
            Claims = new List<Claim>
            {
                new Claim("given_name", "Test"),
                new Claim("family_name", "User"),
                new Claim("email", "test@example.com"),
                new Claim("email_verified", "true"),
                new Claim("role", "user")
            }
        }
    };
}
