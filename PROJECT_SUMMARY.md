# Sample Web App - Project Summary

## Overview
A production-ready ASP.NET Core 8.0 web application demonstrating Azure integration with Key Vault and SQL Database.

## Key Features

### 🏠 Home Page
- Displays application configuration from Azure Key Vault
- Shows sensitive data securely (API keys are masked)
- Modern, responsive UI with Bootstrap 5
- Real-time secret retrieval

### 📊 Dashboard
- Interactive sales analytics dashboard
- Data sourced from Azure SQL Database
- Key metrics: Total Revenue, Units Sold
- Revenue breakdown by Category
- Sales distribution by Region
- Recent sales transaction list

### 🔐 Security Features
- Azure Key Vault integration for secrets management
- DefaultAzureCredential for flexible authentication
- Managed Identity support (Azure hosting)
- Connection string encryption
- No secrets in source code

### 🗄️ Database
- Entity Framework Core 8.0
- Code-first approach with migrations
- Seed data included
- Azure SQL Database ready
- In-memory database option for testing

## Technology Stack

### Backend
- ASP.NET Core 8.0
- C# with nullable reference types
- Entity Framework Core 8.0
- Azure SDK for .NET

### Frontend
- Razor Views
- Bootstrap 5.3
- Bootstrap Icons
- Responsive design

### Azure Services
- **Azure Key Vault**: Secure secret storage
- **Azure SQL Database**: Relational data storage
- **Azure App Service**: Web hosting (deployment ready)
- **Managed Identity**: Passwordless authentication

## Project Structure

```
SampleWebApp/
├── Controllers/
│   ├── HomeController.cs           # Home + Key Vault logic
│   └── DashboardController.cs      # Dashboard + SQL logic
├── Models/
│   ├── HomeViewModel.cs
│   ├── DashboardViewModel.cs
│   ├── SalesData.cs                # EF Core entity
│   └── ErrorViewModel.cs
├── Views/
│   ├── Home/
│   │   ├── Index.cshtml            # Key Vault data display
│   │   └── Privacy.cshtml
│   ├── Dashboard/
│   │   └── Index.cshtml            # SQL data visualization
│   └── Shared/
│       ├── _Layout.cshtml          # Main layout
│       └── Error.cshtml
├── Services/
│   ├── IKeyVaultService.cs
│   └── KeyVaultService.cs          # Key Vault abstraction
├── Data/
│   └── ApplicationDbContext.cs     # EF Core DbContext
├── wwwroot/
│   ├── css/site.css
│   ├── js/site.js
│   └── lib/
├── Database/
│   └── setup.sql                   # Manual DB setup script
├── Docs/
│   ├── KeyVaultSetup.md           # Key Vault guide
│   └── DatabaseSetup.md           # SQL Database guide
├── Scripts/
│   └── Deploy-ToAzure.ps1         # Automated deployment
├── Properties/
│   └── launchSettings.json
├── Program.cs                      # App configuration
├── appsettings.json
├── SampleWebApp.csproj
├── README.md                       # Full documentation
├── QUICKSTART.md                  # Quick start guide
└── .gitignore
```

## NuGet Packages

| Package | Version | Purpose |
|---------|---------|---------|
| Azure.Identity | 1.12.0 | Azure authentication |
| Azure.Security.KeyVault.Secrets | 4.6.0 | Key Vault access |
| Microsoft.EntityFrameworkCore.SqlServer | 8.0.0 | SQL Server provider |
| Microsoft.EntityFrameworkCore.Design | 8.0.0 | EF Core tools |

## Configuration Required

### appsettings.json
```json
{
  "AzureKeyVault": {
    "VaultUri": "https://your-keyvault.vault.azure.net/"
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=your-server.database.windows.net;..."
  }
}
```

## Development Setup

### Option 1: Quick Local Testing (No Azure)
1. Use in-memory database
2. Mock Key Vault service
3. Run: `dotnet run`
4. See: QUICKSTART.md

### Option 2: Full Azure Integration
1. Create Azure Key Vault ([Docs/KeyVaultSetup.md](Docs/KeyVaultSetup.md))
2. Create Azure SQL Database ([Docs/DatabaseSetup.md](Docs/DatabaseSetup.md))
3. Update appsettings.json
4. Run: `az login`
5. Run: `dotnet ef database update`
6. Run: `dotnet run`

## Deployment

### Automated (Recommended)
```powershell
.\Scripts\Deploy-ToAzure.ps1 `
  -ResourceGroupName "myResourceGroup" `
  -Location "eastus" `
  -AppName "myapp"
```

### Manual
See deployment section in README.md

## Security Best Practices Implemented

✅ Secrets stored in Azure Key Vault  
✅ No hardcoded credentials  
✅ Managed Identity support  
✅ HTTPS enforced  
✅ Connection string encryption  
✅ Sensitive data masking in UI  
✅ Error handling for missing secrets  
✅ .gitignore configured  

## Testing Approach

1. **Local Development**
   - In-memory database
   - Mock services
   - Fast iteration

2. **Integration Testing**
   - Azure Key Vault integration
   - SQL Database integration
   - End-to-end flows

3. **Production**
   - Managed Identity
   - Azure SQL Database
   - Full Azure stack

## URLs

- **Home**: `/` or `/Home/Index`
- **Dashboard**: `/Dashboard` or `/Dashboard/Index`
- **Privacy**: `/Home/Privacy`

## Sample Data

The database is seeded with 6 sample products:
- Electronics: Laptop Pro, 4K Monitor, Gaming Headset
- Accessories: Wireless Mouse, Mechanical Keyboard, USB-C Hub

Regions: North America, Europe, Asia

## Key Vault Secrets

Expected secrets:
- `ApplicationTitle`: App title shown on home page
- `WelcomeMessage`: Welcome message on home page
- `ApiKey`: Sample API key (masked in display)

## Extensibility Points

1. **Add More Secrets**: Extend KeyVaultService
2. **Additional Database Tables**: Add to ApplicationDbContext
3. **New Dashboard Charts**: Extend DashboardViewModel
4. **Custom Styling**: Modify wwwroot/css/site.css
5. **Additional Pages**: Add controllers and views

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Key Vault access denied | Run `az login` |
| Cannot connect to database | Check firewall rules |
| Migration fails | Verify connection string |
| 404 errors | Check routing in Program.cs |

## Performance Considerations

- Key Vault calls are cached in service layer
- Database queries use async/await
- EF Core change tracking optimized
- Connection pooling enabled by default

## Monitoring & Logging

- ILogger integration throughout
- Structured logging support
- Application Insights ready
- Error handling with try-catch

## Future Enhancements

- [ ] Add Application Insights telemetry
- [ ] Implement caching (Redis)
- [ ] Add authentication/authorization
- [ ] Chart.js integration for visualizations
- [ ] Export dashboard data to CSV/Excel
- [ ] Real-time updates with SignalR
- [ ] API endpoints for mobile apps
- [ ] Docker containerization

## Documentation Files

1. **README.md** - Comprehensive documentation
2. **QUICKSTART.md** - Get started in 5 minutes
3. **Docs/KeyVaultSetup.md** - Azure Key Vault setup
4. **Docs/DatabaseSetup.md** - Azure SQL Database setup
5. **PROJECT_SUMMARY.md** - This file

## Support Resources

- [ASP.NET Core Docs](https://docs.microsoft.com/aspnet/core/)
- [Azure Key Vault Docs](https://docs.microsoft.com/azure/key-vault/)
- [Azure SQL Database Docs](https://docs.microsoft.com/azure/sql-database/)
- [Entity Framework Core](https://docs.microsoft.com/ef/core/)

## License

This is a sample application for demonstration and learning purposes.

---

**Created**: May 8, 2026  
**Framework**: ASP.NET Core 8.0  
**Status**: Production Ready ✅
