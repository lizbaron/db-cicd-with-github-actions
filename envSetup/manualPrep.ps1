
$azSubscriptionId = az account show --query id -o tsv
$region = "eastus2"
$projectName = "db-cicd-with-github-actions"
$azResourceGroupName = "rg_" + $projectName
$azServicePrincipalName = "sp_" + $projectName

# Create the resource group
az group create -l $region -n $azResourceGroupName

# Ensure the resource group Provisioning State is Suceeded. For example:
# ProvisioningState
# -------------------
# Succeeded
az group list --query "[?name=='$azResourceGroupName'].{provisioningState: properties.provisioningState}" -o table

# Create the service principal.
$spCredential = az ad sp create-for-rbac -n "$azServicePrincipalName" --sdk-auth --role contributor --scopes "/subscriptions/$azSubscriptionId/resourceGroups/$azResourceGroupName" 

# Print the $spCredential (it's a json snippet, fyi) and if using GitHub Actions save it as the AZ_SP_CREDENTIALS secret. (Settings > Secrets > "New repository secret")
$spCredential;

# Print the object id and if using GitHub Actions save it as the AZ_SP_OBJECT_ID secret. (Settings > Secrets > "New repository secret")
az ad sp list --query "[?appDisplayName=='$azServicePrincipalName'].{objectId: objectId}" -o table

# Register required services
az provider register --namespace 'Microsoft.KeyVault' 
az provider register --namespace 'Microsoft.ContainerRegistry' 
az provider register --namespace 'Microsoft.Kubernetes' 

# Ensure all required services are registered. For example:
# Namespace                    RegistrationState
# ---------------------------  -------------------
# Microsoft.KeyVault           Registered
# Microsoft.Kubernetes         Registered
# Microsoft.ContainerRegistry  Registered
az provider list --query "[?contains('Microsoft.KeyVault|Microsoft.Kubernetes|Microsoft.ContainerRegistry',namespace)].{namespace: namespace, registrationState: registrationState}" -o table

