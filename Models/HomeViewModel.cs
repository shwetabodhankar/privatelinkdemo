namespace SampleWebApp.Models;

public class HomeViewModel
{
    public string? ApplicationTitle { get; set; }
    public string? WelcomeMessage { get; set; }
    public string? ApiKey { get; set; }
    public Dictionary<string, string> ConfigurationSettings { get; set; } = new();
}
