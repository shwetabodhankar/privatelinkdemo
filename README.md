# Sample Web App - ASP.NET Core with Azure Integration

This is a sample ASP.NET Core web application that demonstrates integration with Azure Key Vault and Azure SQL Database.

## Features

- **Home Page**: Displays configuration data retrieved from Azure Key Vault
- **Dashboard**: Shows sales analytics and data from Azure SQL Database
- **Secure Configuration**: Uses Azure Key Vault for sensitive settings
- **Modern UI**: Bootstrap 5 with responsive design

## Prerequisites

- .NET 8.0 SDK or later
- Azure subscription
- Azure Key Vault instance
- Azure SQL Database instance

## Setup Instructions

### 1. Azure Key Vault Configuration

1. Create an Azure Key Vault in your Azure subscription
2. Add the following secrets to your Key Vault:
   - `ApplicationTitle`: "My Sample Application" (or any title you prefer)
   - `WelcomeMessage`: "Welcome to our Azure-powered application!"
   - `ApiKey`: "your-secret-api-key-here"

3. Update `appsettings.json` with your Key Vault URI:
   ```json
   "AzureKeyVault": {
     "VaultUri": "https://your-keyvault-name.vault.azure.net/"
   }
   ```

4. Configure authentication:
   - For local development: Use Azure CLI (`az login`)
   - For Azure hosting: Enable Managed Identity on your App Service/VM
   - Grant the identity "Key Vault Secrets User" role on your Key Vault

### 2. Azure SQL Database Configuration

1. Create an Azure SQL Database
2. Update the connection string in `appsettings.json`:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Server=your-server.database.windows.net;Database=SampleDB;User Id=your-username;Password=your-password;Encrypt=True;TrustServerCertificate=False;"
   }
   ```

3. Run database migrations to create the schema and seed data:
   ```bash
   dotnet ef migrations add InitialCreate
   dotnet ef database update
   ```

### 3. Running the Application

1. Restore NuGet packages:
   ```bash
   dotnet restore
   ```

2. Build the application:
   ```bash
   dotnet build
   ```

3. Run the application:
   ```bash
   dotnet run
   ```

4. Open your browser and navigate to `https://localhost:5001` or `http://localhost:5000`

## Project Structure

```
SampleWebApp/
├── Controllers/
│   ├── HomeController.cs       # Handles home page and Key Vault integration
│   └── DashboardController.cs  # Handles dashboard and database queries
├── Models/
│   ├── HomeViewModel.cs
│   ├── DashboardViewModel.cs
│   ├── SalesData.cs            # Database entity
│   └── ErrorViewModel.cs
├── Views/
│   ├── Home/
│   │   ├── Index.cshtml        # Home page view
│   │   └── Privacy.cshtml
│   ├── Dashboard/
│   │   └── Index.cshtml        # Dashboard view
│   └── Shared/
│       ├── _Layout.cshtml      # Main layout
│       └── Error.cshtml
├── Services/
│   ├── IKeyVaultService.cs
│   └── KeyVaultService.cs      # Azure Key Vault service
├── Data/
│   └── ApplicationDbContext.cs # EF Core database context
├── wwwroot/
│   ├── css/
│   └── js/
├── Program.cs                  # Application entry point
└── appsettings.json           # Configuration
```

## Azure Services Used

### Azure Key Vault
- Securely stores application secrets and configuration
- Uses DefaultAzureCredential for authentication
- Supports local development and Azure hosting

### Azure SQL Database
- Stores sales data and analytics
- Entity Framework Core for data access
- Includes seed data for testing

## Security Best Practices

1. **Never commit secrets**: Keep sensitive data in Key Vault, not in code
2. **Use Managed Identity**: When deployed to Azure, use Managed Identity for authentication
3. **Connection String Security**: Store connection strings in Key Vault or use Managed Identity for SQL
4. **HTTPS**: Always use HTTPS in production

## Deployment to Azure

### Deploy to Azure App Service:

1. Create an App Service:
   ```bash
   az webapp create --resource-group myResourceGroup --plan myAppServicePlan --name myWebApp --runtime "DOTNET|8.0"
   ```

2. Enable Managed Identity:
   ```bash
   az webapp identity assign --resource-group myResourceGroup --name myWebApp
   ```

3. Grant Key Vault access:
   ```bash
   az keyvault set-policy --name myKeyVault --object-id <managed-identity-object-id> --secret-permissions get list
   ```

4. Deploy the application:
   ```bash
   dotnet publish -c Release
   az webapp deployment source config-zip --resource-group myResourceGroup --name myWebApp --src publish.zip
   ```

## Troubleshooting

### Key Vault Issues
- Ensure you're authenticated (`az login` for local dev)
- Verify the Key Vault URI is correct
- Check that the identity has proper permissions

### Database Issues
- Verify connection string is correct
- Ensure firewall rules allow your IP
- Run migrations: `dotnet ef database update`

## Learn More

- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/sql-database/)
- [ASP.NET Core Documentation](https://docs.microsoft.com/aspnet/core/)
- [Entity Framework Core](https://docs.microsoft.com/ef/core/)

## License

This is a sample application for demonstration purposes.
