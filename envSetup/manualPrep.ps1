
$azSubscriptionId = az account show --query id -o tsv
$region = "eastus2"
$projectName = "db-cicd-with-github-actions"
$azResourceGroupName = "rg_" + $projectName
$azServicePrincipalName = "sp_" + $projectName

# Create the resource group
az group create -l $region -n $azResourceGroupName

# Ensure the resource group Provisioning State is Suceeded. For example:
$sleepInterval = 10;
$waitTimeLimit = 0;
while ("Succeeded" -ne (az group list --query "[?name=='$azResourceGroupName'].{provisioningState: properties.provisioningState}" -o tsv) -AND $waitTimeLimit -le 60) {
    Start-Sleep $sleepInterval;
    $waitTimeLimit += $sleepInterval;
}

# Create the service principal.
$spCredential = az ad sp create-for-rbac -n "$azServicePrincipalName" --sdk-auth --role contributor --scopes "/subscriptions/$azSubscriptionId/resourceGroups/$azResourceGroupName" 

$spCredential;
Write-Output "";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖   INSTRUCTIONS  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
Write-Output "💖";
Write-Output "💖   Copy the json snippet above and save it as the GitHub Secret `"AZ_SP_CREDENTIALS`"."; 
Write-Output "💖";
Write-Output "💖   Copy the client secret from the json snippet save it as the GitHub Secret `"AZ_SP_CLIENT_SECRET`"."; 
Write-Output "💖";
Write-Output "💖   GitHub secrets can be set by going to Settings > Secrets > `"New repository secret`".";
Write-Output "💖";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";

az ad sp list --query "[?appDisplayName=='$azServicePrincipalName'].{objectId: objectId}" -o table
Write-Output "";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖   INSTRUCTIONS  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
Write-Output "💖";
Write-Output "💖   Copy the object id and save it as the GitHub Secret `"AZ_SP_OBJECT_ID`".";
Write-Output "💖";
Write-Output "💖   GitHub secrets can be set by going to Settings > Secrets > `"New repository secret`".";
Write-Output "💖"; 
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";

# Register required services
az provider register --namespace 'Microsoft.KeyVault' 
az provider register --namespace 'Microsoft.ContainerRegistry' 
az provider register --namespace 'Microsoft.Kubernetes' 

# Wait until all required services are registered.
$waitTimeLimit = 0;
while ((-join (az provider list --query "[?contains('Microsoft.KeyVault|Microsoft.Kubernetes|Microsoft.ContainerRegistry',namespace)].{registrationState: registrationState}" -o tsv)).Replace("Registered","").length -gt 0 -AND $waitTimeLimit -le 300) {
    Start-Sleep $sleepInterval;
    $waitTimeLimit += $sleepInterval;
}

