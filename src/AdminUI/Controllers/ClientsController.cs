using AdminUI.Services;
using Microsoft.AspNetCore.Mvc;

namespace AdminUI.Controllers;

public class ClientsController : Controller
{
    private readonly IIdentityServerAdminService _adminService;

    public ClientsController(IIdentityServerAdminService adminService)
    {
        _adminService = adminService;
    }

    public async Task<IActionResult> Index()
    {
        var clients = await _adminService.GetClientsAsync();
        return View(clients);
    }
}