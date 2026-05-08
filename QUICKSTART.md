# Quick Start Guide

Get the Sample Web App running in 5 minutes!

## For Quick Local Testing (Without Azure)

If you want to run the app immediately without setting up Azure services:

### 1. Modify Program.cs
Comment out or modify the Key Vault configuration to handle null:

```csharp
// Configure Azure Key Vault (optional for local testing)
var keyVaultUri = builder.Configuration["AzureKeyVault:VaultUri"];
if (!string.IsNullOrEmpty(keyVaultUri) && keyVaultUri != "https://your-keyvault-name.vault.azure.net/")
{
    var credential = new DefaultAzureCredential();
    var secretClient = new SecretClient(new Uri(keyVaultUri), credential);
    builder.Services.AddSingleton(secretClient);
}
else
{
    // Mock SecretClient for local testing
    builder.Services.AddSingleton<SecretClient>(sp => null!);
}
```

### 2. Use In-Memory Database
Update Program.cs to use in-memory database:

```csharp
// Configure Database Context
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseInMemoryDatabase("SampleDB"));
```

Don't forget to add the package:
```bash
dotnet add package Microsoft.EntityFrameworkCore.InMemory
```

### 3. Seed Data at Startup
Add this code in Program.cs before `app.Run()`:

```csharp
// Seed database
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    context.Database.EnsureCreated();
}
```

### 4. Run the Application
```bash
dotnet restore
dotnet build
dotnet run
```

Navigate to: https://localhost:5001

## For Full Azure Integration

Follow these guides in order:

1. **Azure Key Vault Setup**: See [Docs/KeyVaultSetup.md](Docs/KeyVaultSetup.md)
2. **Azure SQL Database Setup**: See [Docs/DatabaseSetup.md](Docs/DatabaseSetup.md)
3. **Configuration**: Update `appsettings.json` with your Azure resource details
4. **Authentication**: Run `az login` for local development
5. **Run**: `dotnet run`

## Common Commands

### Restore packages
```bash
dotnet restore
```

### Build
```bash
dotnet build
```

### Run
```bash
dotnet run
```

### Run with watch (auto-reload)
```bash
dotnet watch run
```

### Create migration
```bash
dotnet ef migrations add <MigrationName>
```

### Update database
```bash
dotnet ef database update
```

### Clean
```bash
dotnet clean
```

## Project URLs

- **Home**: https://localhost:5001/
- **Dashboard**: https://localhost:5001/Dashboard
- **Privacy**: https://localhost:5001/Home/Privacy

## Troubleshooting

### "Unable to resolve service for type 'Azure.Security.KeyVault.Secrets.SecretClient'"
- The Key Vault is not configured. Either set up Azure Key Vault or use the mock setup above.

### "Cannot open database"
- Verify your SQL connection string is correct
- Check firewall rules allow your IP
- Or use in-memory database for testing

### "Access denied" when accessing Key Vault
- Run `az login` to authenticate
- Verify you have permissions on the Key Vault

## Next Steps

1. Customize the UI in `Views/` folder
2. Add more secrets to Key Vault
3. Extend the database model in `Models/SalesData.cs`
4. Add more dashboard charts and analytics
5. Deploy to Azure App Service

## Learn More

- [Full README](README.md)
- [Key Vault Setup Guide](Docs/KeyVaultSetup.md)
- [Database Setup Guide](Docs/DatabaseSetup.md)
