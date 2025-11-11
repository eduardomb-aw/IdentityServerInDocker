using Serilog;
using IdentityServer4.Models;
using IdentityServer4;

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

    // Add IdentityServer4 with minimal required resources
    builder.Services.AddIdentityServer()
        .AddInMemoryIdentityResources(GetIdentityResources())
        .AddInMemoryApiScopes(GetApiScopes())
        .AddInMemoryClients(GetClients())
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
        new IdentityServer4.Models.ApiScope("api1", "My API")
    };
}

static IEnumerable<Client> GetClients()
{
    return new List<Client>
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
        }
    };
}