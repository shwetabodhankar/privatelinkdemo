# Complete Azure Deployment Script
# Replicates the entire setup: Key Vault, SQL Server, Database, App Service Plan, Web App
# Based on working configuration from rg-test-ntt

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-test-ntt-vnet",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westus"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Azure Deployment - Complete Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Generate unique resource names
$randomSuffix = Get-Random -Maximum 10000
$keyVaultName = "myapp-kv-$randomSuffix"
$sqlServerName = "myapp-sql-$randomSuffix"
$databaseName = "SampleDB"
$appServicePlanName = "myapp-plan-$randomSuffix"
$webAppName = "myapp-web-$randomSuffix"

Write-Host "Resource Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  Key Vault: $keyVaultName" -ForegroundColor White
Write-Host "  SQL Server: $sqlServerName" -ForegroundColor White
Write-Host "  Database: $databaseName" -ForegroundColor White
Write-Host "  App Service Plan: $appServicePlanName" -ForegroundColor White
Write-Host "  Web App: $webAppName" -ForegroundColor White
Write-Host ""

# Get current user info for SQL Admin
$currentUser = az account show --query user.name -o tsv
$currentUserId = az ad signed-in-user show --query id -o tsv

Write-Host "Current User: $currentUser" -ForegroundColor Green
Write-Host "User Object ID: $currentUserId" -ForegroundColor Green
Write-Host ""

# 1. Create Resource Group
Write-Host "[1/7] Creating Resource Group..." -ForegroundColor Cyan
az group create --name $ResourceGroupName --location $Location --output table
Write-Host ""

# 2. Create Key Vault
Write-Host "[2/7] Creating Key Vault..." -ForegroundColor Cyan
az keyvault create `
    --name $keyVaultName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --enable-rbac-authorization false `
    --output table

Write-Host "Adding secrets to Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $keyVaultName --name "ApplicationTitle" --value "My Azure VNet Application" --output none
az keyvault secret set --vault-name $keyVaultName --name "WelcomeMessage" --value "Welcome to our VNet-integrated application!" --output none
az keyvault secret set --vault-name $keyVaultName --name "ApiKey" --value "vnet-api-key-$(Get-Random -Maximum 100000)" --output none
Write-Host "  ✓ Secrets added successfully" -ForegroundColor Green
Write-Host ""

# 3. Create SQL Server with Azure AD Authentication
Write-Host "[3/7] Creating SQL Server..." -ForegroundColor Cyan
az sql server create `
    --name $sqlServerName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --enable-ad-only-auth `
    --external-admin-principal-type User `
    --external-admin-name $currentUser `
    --external-admin-sid $currentUserId `
    --output table
Write-Host ""

# 4. Configure SQL Server Firewall
Write-Host "[4/7] Configuring SQL Server Firewall..." -ForegroundColor Cyan
$myIp = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content.Trim()
az sql server firewall-rule create `
    --resource-group $ResourceGroupName `
    --server $sqlServerName `
    --name "AllowAzureServices" `
    --start-ip-address 0.0.0.0 `
    --end-ip-address 0.0.0.0 `
    --output none

az sql server firewall-rule create `
    --resource-group $ResourceGroupName `
    --server $sqlServerName `
    --name "AllowMyIP" `
    --start-ip-address $myIp `
    --end-ip-address $myIp `
    --output none
Write-Host "  ✓ Firewall rules configured (Azure Services + $myIp)" -ForegroundColor Green
Write-Host ""

# 5. Create SQL Database (Serverless)
Write-Host "[5/7] Creating SQL Database (Serverless)..." -ForegroundColor Cyan
az sql db create `
    --resource-group $ResourceGroupName `
    --server $sqlServerName `
    --name $databaseName `
    --edition GeneralPurpose `
    --family Gen5 `
    --compute-model Serverless `
    --capacity 1 `
    --auto-pause-delay 60 `
    --output table
Write-Host ""

# 6. Create App Service Plan
Write-Host "[6/7] Creating App Service Plan..." -ForegroundColor Cyan
az appservice plan create `
    --name $appServicePlanName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku B1 `
    --output table
Write-Host ""

# 7. Create Web App
Write-Host "[7/7] Creating Web App..." -ForegroundColor Cyan
az webapp create `
    --name $webAppName `
    --resource-group $ResourceGroupName `
    --plan $appServicePlanName `
    --runtime "dotnet:8" `
    --output table
Write-Host ""

# 8. Enable Managed Identity
Write-Host "[8/9] Enabling Managed Identity..." -ForegroundColor Cyan
$identityJson = az webapp identity assign --name $webAppName --resource-group $ResourceGroupName --output json
$identity = $identityJson | ConvertFrom-Json
$principalId = $identity.principalId
Write-Host "  ✓ Managed Identity Principal ID: $principalId" -ForegroundColor Green
Write-Host ""

# 9. Grant Key Vault Access
Write-Host "[9/10] Granting Key Vault Access..." -ForegroundColor Cyan
az keyvault set-policy `
    --name $keyVaultName `
    --object-id $principalId `
    --secret-permissions get list `
    --output none
Write-Host "  ✓ Key Vault access granted" -ForegroundColor Green
Write-Host ""

# 10. Configure App Settings
Write-Host "[10/11] Configuring App Settings..." -ForegroundColor Cyan
$connectionString = "Server=$sqlServerName.database.windows.net;Database=$databaseName;Authentication=Active Directory Default;Encrypt=True;"
$vaultUri = "https://$keyVaultName.vault.azure.net/"

az webapp config appsettings set `
    --name $webAppName `
    --resource-group $ResourceGroupName `
    --settings `
        "ConnectionStrings__DefaultConnection=$connectionString" `
        "AzureKeyVault__VaultUri=$vaultUri" `
    --output table
Write-Host ""

# 11. Build and Deploy Application
Write-Host "[11/11] Building and Deploying Application..." -ForegroundColor Cyan
Write-Host "  Building application..." -ForegroundColor Yellow
$currentPath = Get-Location
Set-Location "c:\Projects\ntt-portal\SampleWebApp"
dotnet publish -c Release -o ./publish --nologo --verbosity quiet
Compress-Archive -Path ./publish/* -DestinationPath ./publish.zip -Force
Write-Host "  ✓ Application built" -ForegroundColor Green

Write-Host "  Deploying to Azure..." -ForegroundColor Yellow
az webapp deploy `
    --resource-group $ResourceGroupName `
    --name $webAppName `
    --src-path ./publish.zip `
    --type zip `
    --output table
Set-Location $currentPath
Write-Host ""

# 12. Restart Web App
Write-Host "Restarting Web App..." -ForegroundColor Cyan
az webapp restart --name $webAppName --resource-group $ResourceGroupName --output none
Write-Host "  ✓ Web App restarted" -ForegroundColor Green
Write-Host ""

# Generate SQL Script for Database Access
$sqlScript = @"
-- Run this in Azure Portal Query Editor for database: $databaseName
-- Server: $sqlServerName.database.windows.net

-- Create user for the web app's Managed Identity
CREATE USER [$webAppName] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [$webAppName];
ALTER ROLE db_datawriter ADD MEMBER [$webAppName];
ALTER ROLE db_ddladmin ADD MEMBER [$webAppName];

-- Verify the user was created
SELECT name, type_desc FROM sys.database_principals WHERE name = '$webAppName';
"@

$sqlScriptPath = ".\Configure-DatabaseAccess-$webAppName.sql"
$sqlScript | Out-File -FilePath $sqlScriptPath -Encoding utf8
Write-Host "  ✓ SQL script saved to: $sqlScriptPath" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resources Created:" -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  Key Vault: $keyVaultName" -ForegroundColor White
Write-Host "  SQL Server: $sqlServerName.database.windows.net" -ForegroundColor White
Write-Host "  SQL Database: $databaseName" -ForegroundColor White
Write-Host "  App Service Plan: $appServicePlanName" -ForegroundColor White
Write-Host "  Web App: $webAppName" -ForegroundColor White
Write-Host ""
Write-Host "Web App URL: https://$webAppName.azurewebsites.net" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT - Next Steps:" -ForegroundColor Red
Write-Host "1. Run the SQL script: $sqlScriptPath" -ForegroundColor White
Write-Host "2. Go to Azure Portal → SQL Database '$databaseName' → Query Editor" -ForegroundColor White
Write-Host "3. Sign in with Azure AD" -ForegroundColor White
Write-Host "4. Execute the SQL script to grant database access" -ForegroundColor White
Write-Host ""
Write-Host "After completing the SQL script, visit:" -ForegroundColor Cyan
Write-Host "  Home Page: https://$webAppName.azurewebsites.net" -ForegroundColor White
Write-Host "  Dashboard: https://$webAppName.azurewebsites.net/Dashboard" -ForegroundColor White
Write-Host ""
