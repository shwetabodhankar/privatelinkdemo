# Azure Deployment Summary - Two Environments

## Environment 1: Public Connectivity (Demo)
**Resource Group**: `rg-test-ntt`
**Location**: West US
**Purpose**: Demonstrate public connectivity

### Resources:
- **Key Vault**: myapp-kv-8700
  - URI: https://myapp-kv-8700.vault.azure.net/
  - Secrets: ApplicationTitle, WelcomeMessage, ApiKey

- **SQL Server**: myapp-sql-3216.database.windows.net
  - Authentication: Azure AD Only
  - Database: SampleDB (Serverless GP_S_Gen5_1)

- **App Service Plan**: testappplan
  - Type: Windows
  - SKU: Basic (B1)

- **Web App**: myapp-web-5233
  - URL: https://myapp-web-5233.azurewebsites.net
  - Managed Identity: Enabled
  - Status: ✅ Deployed and Running

---

## Environment 2: VNet Configuration
**Resource Group**: `rg-test-ntt-vnet`
**Location**: West US
**Purpose**: VNet-integrated setup (shares App Service Plan with rg-test-ntt)

### Resources:
- **Key Vault**: myapp-kv-8522
  - URI: https://myapp-kv-8522.vault.azure.net/
  - Secrets: ApplicationTitle, WelcomeMessage, ApiKey

- **SQL Server**: myapp-sql-8522.database.windows.net
  - Authentication: Azure AD Only
  - Database: SampleDB (Serverless GP_S_Gen5_1)

- **App Service Plan**: testappplan (from rg-test-ntt)
  - Type: Windows
  - SKU: Basic (B1)
  - Note: Shared across resource groups

- **Web App**: myapp-web-2840
  - URL: https://myapp-web-2840.azurewebsites.net
  - Managed Identity: Enabled
  - Status: ✅ Deployed and Running

---

## Configuration Steps Required

### For Environment 1 (rg-test-ntt):
✅ All configuration complete and working

### For Environment 2 (rg-test-ntt-vnet):
⚠️ **Required**: Run SQL script to grant database access

**Script Location**: `Scripts/Configure-DatabaseAccess-VNet.sql`

**Instructions**:
1. Go to Azure Portal
2. Navigate to: SQL Databases → SampleDB (in myapp-sql-8522)
3. Open Query Editor (authenticate with Azure AD)
4. Run the SQL script:
   ```sql
   CREATE USER [myapp-web-2840] FROM EXTERNAL PROVIDER;
   ALTER ROLE db_datareader ADD MEMBER [myapp-web-2840];
   ALTER ROLE db_datawriter ADD MEMBER [myapp-web-2840];
   ALTER ROLE db_ddladmin ADD MEMBER [myapp-web-2840];
   ```

---

## Access URLs

### Environment 1 (Public):
- Home: https://myapp-web-5233.azurewebsites.net
- Dashboard: https://myapp-web-5233.azurewebsites.net/Dashboard

### Environment 2 (VNet):
- Home: https://myapp-web-2840.azurewebsites.net
- Dashboard: https://myapp-web-2840.azurewebsites.net/Dashboard

---

## Deployment Notes

### Successful Deployments:
- ✅ Both Key Vaults created with secrets
- ✅ Both SQL Servers created with Azure AD authentication
- ✅ Both SQL Databases created (Serverless)
- ✅ Both Web Apps deployed and running
- ✅ Managed Identities enabled for both web apps
- ✅ Key Vault access policies configured
- ✅ App Settings configured for both web apps
- ✅ Firewall rules configured for Azure Services + local IP

### Quota Limitations:
- ❌ Cannot create new App Service Plans (0 quota for Free, Basic, Standard tiers)
- ✅ Workaround: Using existing testappplan across both resource groups

### Architecture Comparison:
| Component | Environment 1 (Public) | Environment 2 (VNet) |
|-----------|----------------------|-------------------|
| Resource Group | rg-test-ntt | rg-test-ntt-vnet |
| Key Vault | myapp-kv-8700 | myapp-kv-8522 |
| SQL Server | myapp-sql-3216 | myapp-sql-8522 |
| SQL Database | SampleDB | SampleDB |
| App Service Plan | testappplan | testappplan (shared) |
| Web App | myapp-web-5233 | myapp-web-2840 |
| Connectivity | Public | Public (VNet ready) |

---

## Redeployment Commands

### Redeploy Environment 1:
```powershell
cd c:\Projects\ntt-portal\SampleWebApp
dotnet publish -c Release -o ./publish
Compress-Archive -Path ./publish/* -DestinationPath ./publish.zip -Force
az webapp deploy --resource-group rg-test-ntt --name myapp-web-5233 --src-path ./publish.zip --type zip
```

### Redeploy Environment 2:
```powershell
cd c:\Projects\ntt-portal\SampleWebApp
dotnet publish -c Release -o ./publish
Compress-Archive -Path ./publish/* -DestinationPath ./publish.zip -Force
az webapp deploy --resource-group rg-test-ntt-vnet --name myapp-web-2840 --src-path ./publish.zip --type zip
```

---

## Next Steps for VNet Integration

To fully enable VNet integration for Environment 2:
1. Create VNet and subnet in rg-test-ntt-vnet
2. Enable VNet integration on myapp-web-2840
3. Configure private endpoints for Key Vault and SQL Server
4. Update firewall rules to restrict public access

---

Generated: May 8, 2026
