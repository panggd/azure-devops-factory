#!/bin/sh
set -e  # Exit immediately on error

# Optional: use argument if provided, default to terraform.tfvars
TFVARS_FILE=${1:-terraform.tfvars}

echo "Using tfvars file: $TFVARS_FILE"

# Check if the tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
  echo "Error: tfvars file '$TFVARS_FILE' not found."
  echo "Usage: ./init.sh [optional-tfvars-file]"
  exit 1
fi

# Configuration (feel free to change accordingly)
RESOURCE_GROUP="rg_devops_factory"
STORAGE_ACCOUNT_NAME="stdevopsfactoryorg"
LOCATION="southeastasia"
SP_NAME="sp_devops_factory"
SP_ROLE="Contributor" # (define a fine-grained role for least privilege access)
KV_NAME="kv-devops-factory"  # (must be globally unique)
SECRET_NAME="devops-sp-secret"  # Name for stored secret
DEVOPS_ORG_NAME="<YOUR_AZURE_DEVOPS_ORG_ID>" # (must be globally unique)

# Check if Azure CLI is installed
if ! command -v az >/dev/null 2>&1; then
    echo "Error: Azure CLI not found. Please install it first."
    exit 1
fi

# Get current subscription ID
ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv) || {
    echo "Error: Failed to get subscription ID"
    exit 1
}
export ARM_SUBSCRIPTION_ID

# Check/Register Storage service
if ! az provider show --namespace Microsoft.Storage >/dev/null 2>&1; then
    az provider register --namespace Microsoft.Storage
fi

# Check/Create Resource Group
if ! az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "Creating resource group: $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
    echo "Resource group $RESOURCE_GROUP already exists"
fi

# Check/Create Storage Account
if ! az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
    az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --allow-blob-public-access false
else
    echo "Storage account $STORAGE_ACCOUNT_NAME already exists"
fi

# Check/Create Key Vault
if ! az keyvault show --name "$KV_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "Creating Key Vault: $KV_NAME"
    az keyvault create --name "$KV_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku standard
else
    echo "Key Vault $KV_NAME already exists"
fi

# Check for existing service principal
SP_APP_ID=$(az ad sp list --display-name "$SP_NAME" --query [].appId -o tsv)

if [ -z "$SP_APP_ID" ]; then
    echo "Creating service principal: $SP_NAME"
    SP_JSON=$(az ad sp create-for-rbac --name "$SP_NAME" --role $SP_ROLE --scopes "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" --years 1 -o json)

    # Extract credentials
    ARM_CLIENT_ID=$(echo "$SP_JSON" | grep appId | cut -d'"' -f4)
    ARM_CLIENT_SECRET=$(echo "$SP_JSON" | grep password | cut -d'"' -f4)

    # Assign Key Vault access to current user
    echo "Creating role assignment for current user"
    az role assignment create \
        --role "Key Vault Secrets Officer" \
        --assignee-object-id "$(az ad signed-in-user show --query id -o tsv)" \
        --assignee-principal-type User \
        --scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KV_NAME"

    # Assign Key Vault access to devops factory service principal
    echo "Creating role assignment for devops factory service principals"
    az role assignment create \
        --role "Key Vault Secrets Officer" \
        --assignee-object-id $ARM_CLIENT_ID \
        --assignee-principal-type ServicePrincipal \
        --scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KV_NAME"

    echo "Waiting 2 minutes for rbac propagation..."
    sleep 120

    # Store secret in Key Vault
    echo "Storing client secret in Key Vault"
    az keyvault secret set --vault-name "$KV_NAME" \
        --name "$SECRET_NAME" \
        --value "$ARM_CLIENT_SECRET" >/dev/null
else
    echo "Service principal $SP_NAME already exists"
    # Retrieve secret from Key Vault
    echo "Retrieving client secret from Key Vault"
    ARM_CLIENT_SECRET=$(az keyvault secret show \
        --vault-name "$KV_NAME" \
        --name "$SECRET_NAME" \
        --query "value" -o tsv)

    if [ -z "$ARM_CLIENT_SECRET" ]; then
        echo "Error: Secret not found in Key Vault"
        exit 1
    fi

    ARM_CLIENT_ID=$SP_APP_ID
    ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
fi

# Verify environment variables
if [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_TENANT_ID" ]; then
    echo "Error: Missing service principal credentials"
    exit 1
fi

# Secure output (prevent secret exposure)
set +x  # Disable command echoing
export ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_TENANT_ID

# Initialize Terraform
terraform init
terraform plan -var-file="$TFVARS_FILE"

echo "That's it for the init script. Please manually configure Azure DevOps at https://dev.azure.com/$DEVOPS_ORG_NAME"

# Cleanup sensitive data (best effort)
unset ARM_CLIENT_ID ARM_CLIENT_SECRET
