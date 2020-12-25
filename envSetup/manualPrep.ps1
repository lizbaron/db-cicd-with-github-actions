
$azSubscriptionId = az account show --query id -o tsv
$region = "eastus2"
$projectName = "db-cicd-with-github-actions"
$azResourceGroupName = "rg_" + $projectName
$azServicePrincipalName = "sp_" + $projectName

$rgDetails = az group create -l $region -n $azResourceGroupName
# Pro Tip: Make sure that Provisioning State is Suceeded.

$spCredential = az ad sp create-for-rbac -n "$azServicePrincipalName" --sdk-auth --role contributor --scopes "/subscriptions/$azSubscriptionId/resourceGroups/$azResourceGroupName" 

# Print the $spCredential (it's a json snippet, fyi) and save it in your secrets.
$spCredential;

# Get the object id save it to your secrets.
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

