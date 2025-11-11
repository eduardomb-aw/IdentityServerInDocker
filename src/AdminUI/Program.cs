using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Authentication.Cookies;
using AdminUI.Services;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File("logs/adminui.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    // Configure URLs explicitly for AdminUI
    if (builder.Environment.IsDevelopment() && Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true")
    {
        // Running in Docker container - listen on all interfaces
        builder.WebHost.UseUrls("http://+:5002", "https://+:5003");
    }
    else
    {
        // Running locally - listen on localhost only  
        builder.WebHost.UseUrls("http://localhost:5002", "https://localhost:5003");
    }

    builder.Host.UseSerilog(Log.Logger);

    // Add services to the container
    builder.Services.AddRazorPages();
    builder.Services.AddControllersWithViews();

    var identityServerBaseUrl = builder.Configuration["IdentityServerOptions:BaseUrl"] ?? "https://localhost:5001";

    // Add HttpClient for communicating with IdentityServer
    builder.Services.AddHttpClient<IIdentityServerAdminService, IdentityServerAdminService>(client =>
    {
        client.BaseAddress = new Uri(identityServerBaseUrl);
        client.Timeout = TimeSpan.FromSeconds(30);
    }).ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler()
    {
        ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true // Only for development
    });

    // Add Authentication
    builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
    })
    .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
        options.AccessDeniedPath = "/Account/AccessDenied";
    })
    .AddOpenIdConnect(OpenIdConnectDefaults.AuthenticationScheme, options =>
    {
        options.Authority = identityServerBaseUrl;
        options.ClientId = "adminui-client";
        options.ClientSecret = "adminui-secret";
        options.ResponseType = "code";
        options.SaveTokens = true;
        options.GetClaimsFromUserInfoEndpoint = true;
        options.RequireHttpsMetadata = false; // Only for development

        options.Scope.Clear();
        options.Scope.Add("openid");
        options.Scope.Add("profile");
        options.Scope.Add("api1");
    });

    // Add CORS
    builder.Services.AddCors(options =>
    {
        options.AddPolicy("AllowIdentityServer",
            policy => policy
                .WithOrigins("http://localhost:5000", "https://localhost:5001")
                .AllowAnyHeader()
                .AllowAnyMethod());
    });

    var app = builder.Build();

    // Configure the HTTP request pipeline
    if (!app.Environment.IsDevelopment())
    {
        app.UseExceptionHandler("/Error");
        app.UseHsts();
    }

    app.UseHttpsRedirection();
    app.UseStaticFiles();

    app.UseCors("AllowIdentityServer");
    app.UseRouting();

    app.UseAuthentication();
    app.UseAuthorization();

    app.MapRazorPages();
    app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Home}/{action=Index}/{id?}");

    // Add a simple health check endpoint
    app.MapGet("/health", () => Results.Ok(new { 
        status = "healthy", 
        service = "AdminUI", 
        timestamp = DateTime.UtcNow,
        identityServerUrl = identityServerBaseUrl
    }));

    Log.Information("Starting Admin UI on http://localhost:5002 and https://localhost:5003");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Admin UI terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}