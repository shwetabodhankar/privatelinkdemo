using Azure.Security.KeyVault.Secrets;
using Azure;

namespace SampleWebApp.Services;

public class KeyVaultService : IKeyVaultService
{
    private readonly SecretClient _secretClient;
    private readonly ILogger<KeyVaultService> _logger;

    public KeyVaultService(SecretClient secretClient, ILogger<KeyVaultService> logger)
    {
        _secretClient = secretClient;
        _logger = logger;
    }

    public async Task<string?> GetSecretAsync(string secretName)
    {
        try
        {
            KeyVaultSecret secret = await _secretClient.GetSecretAsync(secretName);
            return secret.Value;
        }
        catch (RequestFailedException ex)
        {
            _logger.LogError(ex, "Error retrieving secret {SecretName} from Key Vault", secretName);
            return null;
        }
    }

    public async Task<Dictionary<string, string>> GetMultipleSecretsAsync(string[] secretNames)
    {
        var secrets = new Dictionary<string, string>();

        foreach (var secretName in secretNames)
        {
            try
            {
                var secretValue = await GetSecretAsync(secretName);
                if (secretValue != null)
                {
                    secrets[secretName] = secretValue;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving secret {SecretName}", secretName);
                secrets[secretName] = "Error retrieving secret";
            }
        }

        return secrets;
    }
}
