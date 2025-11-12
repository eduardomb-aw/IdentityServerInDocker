using Microsoft.AspNetCore.Mvc;
using IdentityServer4.Services;
using IdentityServer4.Models;
using IdentityServer4.Extensions;
using IdentityServer4.Events;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;

namespace IdentityServer.Controllers
{
    public class AccountController : Controller
    {
        private readonly IIdentityServerInteractionService _interaction;
        private readonly IEventService _events;

        public AccountController(
            IIdentityServerInteractionService interaction,
            IEventService events)
        {
            _interaction = interaction;
            _events = events;
        }

        [HttpGet]
        public async Task<IActionResult> Login(string returnUrl)
        {
            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(string username, string password, string returnUrl)
        {
            // Input validation
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                ViewData["Error"] = "Username and password are required";
                ViewData["ReturnUrl"] = returnUrl;
                return View();
            }

            // Simple hardcoded check for demo/development purposes only
            // TODO: Replace with proper user authentication service in production
            if (username == "testuser" && password == "password")
            {
                var user = new ClaimsPrincipal(new ClaimsIdentity(new[]
                {
                    new Claim("sub", "1"),
                    new Claim("name", "Test User"),
                    new Claim("email", "test@example.com")
                }, "cookie"));

                await HttpContext.SignInAsync("idsrv", user);

                await _events.RaiseAsync(new UserLoginSuccessEvent(username, "1", username));

                if (_interaction.IsValidReturnUrl(returnUrl))
                {
                    return Redirect(returnUrl);
                }

                return Redirect("~");
            }

            // Log failed login attempt (in production, implement proper logging and rate limiting)
            await _events.RaiseAsync(new UserLoginFailureEvent(username, "invalid credentials"));
            
            ViewData["Error"] = "Invalid username or password";
            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> Logout(string logoutId)
        {
            await HttpContext.SignOutAsync("idsrv");
            
            var logout = await _interaction.GetLogoutContextAsync(logoutId);
            if (!string.IsNullOrEmpty(logout?.PostLogoutRedirectUri))
            {
                return Redirect(logout.PostLogoutRedirectUri);
            }

            return Redirect("~");
        }
    }
}