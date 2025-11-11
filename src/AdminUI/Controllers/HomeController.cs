using AdminUI.Services;
using Microsoft.AspNetCore.Mvc;

namespace AdminUI.Controllers;

public class HomeController : Controller
{
    private readonly IIdentityServerAdminService _adminService;

    public HomeController(IIdentityServerAdminService adminService)
    {
        _adminService = adminService;
    }

    public async Task<IActionResult> Index()
    {
        var clients = await _adminService.GetClientsAsync();
        var apiScopes = await _adminService.GetApiScopesAsync();
        var identityResources = await _adminService.GetIdentityResourcesAsync();
        var discoveryInfo = await _adminService.GetDiscoveryInfoAsync();

        ViewBag.ClientCount = clients.Count;
        ViewBag.ApiScopeCount = apiScopes.Count;
        ViewBag.IdentityResourceCount = identityResources.Count;
        ViewBag.IdentityServerStatus = discoveryInfo != null ? "Connected" : "Disconnected";
        ViewBag.DiscoveryInfo = discoveryInfo;

        return View();
    }
}