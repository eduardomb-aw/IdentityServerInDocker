using Microsoft.AspNetCore.Mvc;
using IdentityServer4.Services;
using IdentityServer4.Models;
using IdentityServer4.Extensions;
using IdentityServer4.Events;
using IdentityServer4.Test;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;

namespace IdentityServer.Controllers
{
    public class AccountController : Controller
    {
        private readonly IIdentityServerInteractionService _interaction;
        private readonly IEventService _events;
        private readonly TestUserStore _users;

        public AccountController(
            IIdentityServerInteractionService interaction,
            IEventService events,
            TestUserStore users)
        {
            _interaction = interaction;
            _events = events;
            _users = users;
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

            // Authenticate against configured TestUsers
            if (_users.ValidateCredentials(username, password))
            {
                var user = _users.FindByUsername(username);
                var principal = new ClaimsPrincipal(new ClaimsIdentity(user.Claims, "cookie", "name", "role"));

                await HttpContext.SignInAsync("idsrv", principal);

                await _events.RaiseAsync(new UserLoginSuccessEvent(username, user.SubjectId, username));

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