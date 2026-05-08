# Azure Deployment Script
# This script documents the deployment of the Sample Web App to Azure
# 
# DEPLOYMENT COMPLETED: May 8, 2026
# Resource Group: rg-test-ntt
# Location: West US
# 
# Resources Created:
# - Key Vault: myapp-kv-8700
# - SQL Server: myapp-sql-3216.database.windows.net
# - SQL Database: SampleDB (Serverless GP_S_Gen5_1)
# - App Service Plan: testappplan (Windows)
# - Web App: myapp-web-5233
# 
# Web App URL: https://myapp-web-5233.azurewebsites.net
# 
# To redeploy:
# 1. Build: dotnet publish -c Release -o ./publish
# 2. Package: Compress-Archive -Path ./publish/* -DestinationPath ./publish.zip -Force
# 3. Deploy: az webapp deploy --resource-group rg-test-ntt --name myapp-web-5233 --src-path ./publish.zip --type zip

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-test-ntt",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westus",
    
    [Parameter(Mandatory=$false)]
    [string]$WebAppName = "myapp-web-5233",
    
    [string]$SqlAdminPassword
)

Write-Host "Starting Azure deployment..." -ForegroundColor Green

# Generate unique names
$keyVaultName = "$AppName-kv-$(Get-Random -Maximum 10000)"
$sqlServerName = "$AppName-sql-$(Get-Random -Maximum 10000)"
$appServicePlanName = "$AppName-plan"
$webAppName = "$AppName-web"

Write-Host "Resource names:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroupName"
Write-Host "  Key Vault: $keyVaultName"
Write-Host "  SQL Server: $sqlServerName"
Write-Host "  App Service Plan: $appServicePlanName"
Write-Host "  Web App: $webAppName"
Write-Host ""

# 1. Create Resource Group
Write-Host "Creating resource group..." -ForegroundColor Cyan
az group create --name $ResourceGroupName --location $Location

# 2. Create Key Vault
Write-Host "Creating Key Vault..." -ForegroundColor Cyan
az keyvault create `
  --name $keyVaultName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --enable-rbac-authorization false

# 3. Add secrets to Key Vault
Write-Host "Adding secrets to Key Vault..." -ForegroundColor Cyan
az keyvault secret set --vault-name $keyVaultName --name "ApplicationTitle" --value "My Azure Application"
az keyvault secret set --vault-name $keyVaultName --name "WelcomeMessage" --value "Welcome to our Azure-powered application!"
az keyvault secret set --vault-name $keyVaultName --name "ApiKey" --value "sample-api-key-$(Get-Random -Maximum 100000)"

# 4. Create SQL Server
Write-Host "Creating SQL Server..." -ForegroundColor Cyan
if ([string]::IsNullOrEmpty($SqlAdminPassword)) {
    $SqlAdminPassword = "P@ssw0rd$(Get-Random -Maximum 10000)!"
    Write-Host "Generated SQL password: $SqlAdminPassword" -ForegroundColor Yellow
}

az sql server create `
  --name $sqlServerName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --admin-user sqladmin `
  --admin-password $SqlAdminPassword

# 5. Configure SQL Server firewall
Write-Host "Configuring SQL Server firewall..." -ForegroundColor Cyan
az sql server firewall-rule create `
  --resource-group $ResourceGroupName `
  --server $sqlServerName `
  --name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0

# 6. Create SQL Database
Write-Host "Creating SQL Database..." -ForegroundColor Cyan
az sql db create `
  --resource-group $ResourceGroupName `
  --server $sqlServerName `
  --name SampleDB `
  --service-objective Basic

# 7. Create App Service Plan
Write-Host "Creating App Service Plan..." -ForegroundColor Cyan
az appservice plan create `
  --name $appServicePlanName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --sku B1 `
  --is-linux

# 8. Create Web App
Write-Host "Creating Web App..." -ForegroundColor Cyan
az webapp create `
  --name $webAppName `
  --resource-group $ResourceGroupName `
  --plan $appServicePlanName `
  --runtime "DOTNET|8.0"

# 9. Enable Managed Identity
Write-Host "Enabling Managed Identity..." -ForegroundColor Cyan
$identityJson = az webapp identity assign `
  --resource-group $ResourceGroupName `
  --name $webAppName | ConvertFrom-Json

$principalId = $identityJson.principalId

# 10. Grant Key Vault access to Web App
Write-Host "Granting Key Vault access..." -ForegroundColor Cyan
az keyvault set-policy `
  --name $keyVaultName `
  --object-id $principalId `
  --secret-permissions get list

# 11. Configure App Settings
Write-Host "Configuring application settings..." -ForegroundColor Cyan
$keyVaultUri = "https://$keyVaultName.vault.azure.net/"
$connectionString = "Server=$sqlServerName.database.windows.net;Database=SampleDB;User Id=sqladmin;Password=$SqlAdminPassword;Encrypt=True;"

az webapp config appsettings set `
  --resource-group $ResourceGroupName `
  --name $webAppName `
  --settings `
    "AzureKeyVault__VaultUri=$keyVaultUri" `
    "ASPNETCORE_ENVIRONMENT=Production"

az webapp config connection-string set `
  --resource-group $ResourceGroupName `
  --name $webAppName `
  --connection-string-type SQLAzure `
  --settings DefaultConnection="$connectionString"

# 12. Build and publish application
Write-Host "Building application..." -ForegroundColor Cyan
dotnet publish -c Release -o ./publish

# 13. Deploy to Azure
Write-Host "Deploying to Azure..." -ForegroundColor Cyan
Compress-Archive -Path ./publish/* -DestinationPath ./publish.zip -Force
az webapp deployment source config-zip `
  --resource-group $ResourceGroupName `
  --name $webAppName `
  --src ./publish.zip

# Cleanup
Remove-Item -Path ./publish -Recurse -Force
Remove-Item -Path ./publish.zip -Force

# Output summary
Write-Host ""
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Resource Details:" -ForegroundColor Yellow
Write-Host "  Web App URL: https://$webAppName.azurewebsites.net"
Write-Host "  Resource Group: $ResourceGroupName"
Write-Host "  Key Vault: $keyVaultName"
Write-Host "  SQL Server: $sqlServerName.database.windows.net"
Write-Host "  SQL Database: SampleDB"
Write-Host "  SQL Admin User: sqladmin"
Write-Host "  SQL Admin Password: $SqlAdminPassword"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Run database migrations: dotnet ef database update"
Write-Host "  2. Visit: https://$webAppName.azurewebsites.net"
Write-Host ""
