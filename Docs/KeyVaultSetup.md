# Setup Guide: Azure Key Vault

This guide will help you set up Azure Key Vault for the Sample Web App.

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
$KEYVAULT_NAME="mykeyvault$(Get-Random -Maximum 10000)"
```

## Step 3: Create Resource Group (if needed)
```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

## Step 4: Create Key Vault
```bash
az keyvault create `
  --name $KEYVAULT_NAME `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --enable-rbac-authorization false
```

## Step 5: Add Secrets
```bash
az keyvault secret set --vault-name $KEYVAULT_NAME --name "ApplicationTitle" --value "My Sample Application"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "WelcomeMessage" --value "Welcome to our Azure-powered application!"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "ApiKey" --value "sample-api-key-12345"
```

## Step 6: Grant Access to Your User Account
```bash
$USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
az keyvault set-policy --name $KEYVAULT_NAME --object-id $USER_OBJECT_ID --secret-permissions get list
```

## Step 7: Update appsettings.json
Update the `appsettings.json` file with your Key Vault URI:
```json
{
  "AzureKeyVault": {
    "VaultUri": "https://<your-keyvault-name>.vault.azure.net/"
  }
}
```

Replace `<your-keyvault-name>` with your actual Key Vault name (the value of $KEYVAULT_NAME).

## For Azure App Service Deployment

### Enable Managed Identity
```bash
az webapp identity assign --resource-group $RESOURCE_GROUP --name <your-webapp-name>
```

### Grant Key Vault Access
```bash
$WEBAPP_IDENTITY=$(az webapp identity show --resource-group $RESOURCE_GROUP --name <your-webapp-name> --query principalId -o tsv)
az keyvault set-policy --name $KEYVAULT_NAME --object-id $WEBAPP_IDENTITY --secret-permissions get list
```

## Verify Setup
Test that you can read secrets:
```bash
az keyvault secret show --vault-name $KEYVAULT_NAME --name "ApplicationTitle" --query value -o tsv
```

## Troubleshooting

### "Access denied" errors
- Ensure you're logged in with `az login`
- Verify your user has proper permissions on the Key Vault
- Check that the Key Vault URI is correct in appsettings.json

### Local development authentication
The app uses `DefaultAzureCredential` which tries multiple authentication methods:
1. Environment variables
2. Managed Identity (when deployed to Azure)
3. Visual Studio credentials
4. Azure CLI credentials (`az login`)
5. Azure PowerShell

For local development, ensure you've run `az login`.

## Security Best Practices
1. Use RBAC (Role-Based Access Control) in production
2. Enable soft-delete and purge protection
3. Regularly rotate secrets
4. Use Managed Identity when deployed to Azure
5. Never commit secrets to source control
