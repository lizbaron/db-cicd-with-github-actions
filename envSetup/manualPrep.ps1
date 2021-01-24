Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $projectName  = "db-cicd-with-github-actions"
);


$azSubscriptionId = az account show --query id -o tsv
$region = "eastus2"
$azResourceGroupName = "rg_" + $projectName
$azServicePrincipalName = "sp_" + $projectName

# Create the resource group
az group create -l $region -n $azResourceGroupName

# Ensure the resource group Provisioning State is Suceeded. For example:
$sleepInterval = 10;
$waitTimeLimit = 0;
while ("Succeeded" -ne (az group list --query "[?name=='$azResourceGroupName'].{provisioningState: properties.provisioningState}" -o tsv)) {
    Start-Sleep $sleepInterval;
    $waitTimeLimit += $sleepInterval;
    if($waitTimeLimit -ge 60){
        throw "Something catastrophic has happened! The expected provisioning state was not found after $waitTimeLimit seconds.";
    }

}

# Create the service principal.
$spCredential = az ad sp create-for-rbac -n "$azServicePrincipalName" --sdk-auth --role contributor --scopes "/subscriptions/$azSubscriptionId/resourceGroups/$azResourceGroupName" 

$spCredential;
Write-Output "";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖   INSTRUCTIONS  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
Write-Output "💖";
Write-Output "💖   Copy the json snippet above and save it as the GitHub Secret `"AZ_SP_CRED_$projectName`"."; 
Write-Output "💖";
Write-Output "💖   GitHub secrets can be set by going to Settings > Secrets > `"New repository secret`".";
Write-Output "💖";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";

$serviceProviders = 'Microsoft.KeyVault', 'Microsoft.Kubernetes', 'Microsoft.ContainerRegistry';

# Register required services
foreach ($item in $serviceProviders) {
    az provider register --namespace $item;
}

# Wait until all required services are registered.
Write-Output "";
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
Write-Output "💖   Waiting for registration of service providers."; 
Write-Output "💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖  💖";
$waitTimeLimit = 0;
while ((az provider list --query ("[?contains('", ($serviceProviders -join '|'), "',namespace)].{registrationState: registrationState}" -join "") -o tsv) -join "" -ne "Registered" * $serviceProviders.count) {
    Start-Sleep $sleepInterval;
    $waitTimeLimit += $sleepInterval;
    if($waitTimeLimit -ge 300){
        throw "Something catastrophic has happened! The expected registration states were not found after $waitTimeLimit seconds.";
    }
}

