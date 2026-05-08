using Microsoft.AspNetCore.Mvc;
using SampleWebApp.Models;
using SampleWebApp.Services;
using System.Diagnostics;

namespace SampleWebApp.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly IKeyVaultService _keyVaultService;

    public HomeController(ILogger<HomeController> logger, IKeyVaultService keyVaultService)
    {
        _logger = logger;
        _keyVaultService = keyVaultService;
    }

    public async Task<IActionResult> Index()
    {
        var model = new HomeViewModel();

        try
        {
            // Retrieve secrets from Azure Key Vault
            var secretNames = new[] { "ApplicationTitle", "WelcomeMessage", "ApiKey" };
            var secrets = await _keyVaultService.GetMultipleSecretsAsync(secretNames);

            model.ApplicationTitle = secrets.ContainsKey("ApplicationTitle") 
                ? secrets["ApplicationTitle"] 
                : "Sample Web Application";

            model.WelcomeMessage = secrets.ContainsKey("WelcomeMessage") 
                ? secrets["WelcomeMessage"] 
                : "Welcome to the Sample Web Application";

            model.ApiKey = secrets.ContainsKey("ApiKey") 
                ? MaskSecret(secrets["ApiKey"]) 
                : "Not configured";

            model.ConfigurationSettings = secrets.ToDictionary(
                kvp => kvp.Key,
                kvp => kvp.Key == "ApiKey" ? MaskSecret(kvp.Value) : kvp.Value
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving data from Key Vault");
            model.ApplicationTitle = "Sample Web Application";
            model.WelcomeMessage = "Welcome! (Key Vault data unavailable)";
            model.ApiKey = "Unable to retrieve";
        }

        return View(model);
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }

    private string MaskSecret(string secret)
    {
        if (string.IsNullOrEmpty(secret)) return "****";
        if (secret.Length <= 4) return "****";
        return secret.Substring(0, 4) + new string('*', Math.Min(secret.Length - 4, 8));
    }
}
