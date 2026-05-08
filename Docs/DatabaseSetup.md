# Setup Guide: Azure SQL Database

This guide will help you set up Azure SQL Database for the Sample Web App.

## Prerequisites
- Azure subscription
- Azure CLI installed (`az`)

## Step 1: Login to Azure
```bash
az login
```

## Step 2: Set Variables
```bash
$RESOURCE_GROUP="myResourceGroup"
$LOCATION="eastus"
$SERVER_NAME="mysqlserver$(Get-Random -Maximum 10000)"
$DATABASE_NAME="SampleDB"
$ADMIN_USER="sqladmin"
$ADMIN_PASSWORD="YourStrongPassword123!"  # Change this!
```

## Step 3: Create Resource Group (if needed)
```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

## Step 4: Create SQL Server
```bash
az sql server create `
  --name $SERVER_NAME `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --admin-user $ADMIN_USER `
  --admin-password $ADMIN_PASSWORD
```

## Step 5: Configure Firewall Rules
Allow Azure services:
```bash
az sql server firewall-rule create `
  --resource-group $RESOURCE_GROUP `
  --server $SERVER_NAME `
  --name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0
```

Allow your local IP:
```bash
$MY_IP=$(Invoke-RestMethod -Uri "https://api.ipify.org")
az sql server firewall-rule create `
  --resource-group $RESOURCE_GROUP `
  --server $SERVER_NAME `
  --name AllowMyIP `
  --start-ip-address $MY_IP `
  --end-ip-address $MY_IP
```

## Step 6: Create Database
```bash
az sql db create `
  --resource-group $RESOURCE_GROUP `
  --server $SERVER_NAME `
  --name $DATABASE_NAME `
  --service-objective Basic
```

## Step 7: Get Connection String
```bash
az sql db show-connection-string --client ado.net --name $DATABASE_NAME --server $SERVER_NAME
```

## Step 8: Update appsettings.json
Update the connection string in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=<server-name>.database.windows.net;Database=SampleDB;User Id=<admin-user>;Password=<admin-password>;Encrypt=True;TrustServerCertificate=False;"
  }
}
```

Replace:
- `<server-name>` with your SQL server name
- `<admin-user>` with your admin username
- `<admin-password>` with your admin password

## Step 9: Create Database Schema

### Option A: Using EF Core Migrations (Recommended)

Install EF Core tools (if not already installed):
```bash
dotnet tool install --global dotnet-ef
```

Create and apply migration:
```bash
cd c:\Projects\ntt-portal\SampleWebApp
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### Option B: Using SQL Script
Execute the SQL script in `Database/setup.sql` using Azure Data Studio or SQL Server Management Studio.

## Step 10: Verify Setup
Run the application and navigate to the Dashboard page to see the data.

## Using Managed Identity (Recommended for Production)

### Enable Managed Identity on App Service
```bash
az webapp identity assign --resource-group $RESOURCE_GROUP --name <your-webapp-name>
```

### Grant Database Access
Connect to your SQL database and run:
```sql
CREATE USER [<webapp-name>] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [<webapp-name>];
ALTER ROLE db_datawriter ADD MEMBER [<webapp-name>];
```

### Update Connection String
For Managed Identity authentication:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=<server-name>.database.windows.net;Database=SampleDB;Authentication=Active Directory Default;Encrypt=True;"
  }
}
```

## Troubleshooting

### Cannot connect to database
- Verify firewall rules include your IP address
- Check that the server name is correct
- Ensure credentials are correct

### Migrations fail
- Verify the connection string is correct
- Check that you have write permissions
- Ensure the database exists

### "Login failed for user" error
- Verify username and password
- Check that the SQL Server firewall allows your IP
- Ensure the database exists

## Cost Optimization
- Use Basic tier for development/testing ($5/month)
- Scale up to Standard or Premium for production
- Consider serverless tier for variable workloads
- Set up auto-pause for development databases

## Security Best Practices
1. Use Managed Identity in production (no passwords in connection strings)
2. Never commit connection strings with passwords to source control
3. Use Azure Key Vault to store connection strings
4. Enable Advanced Threat Protection
5. Regularly review and update firewall rules
6. Use strong passwords (or better yet, passwordless authentication)
7. Enable encryption at rest (enabled by default)
8. Use SSL/TLS for connections (Encrypt=True)

## Monitoring
- Enable diagnostic logs
- Set up alerts for CPU, memory, and storage
- Use Query Performance Insights
- Monitor with Application Insights
