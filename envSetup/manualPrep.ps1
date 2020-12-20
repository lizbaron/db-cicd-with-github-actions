
$azSubscriptionId = "xxx-xxx-xxx"
$region = "eastus2"
$projectName = "db-cicd-with-github-actions"
$azResourceGroupName = "rg_" + $projectName
$azServicePrincipalName = "sp_" + $projectName

$rgDetails = az group create -l $region -n $azResourceGroupName
# Pro Tip: Make sure that Provisioning State is Suceeded.

$spCredential = az ad sp create-for-rbac -n "$azServicePrincipalName" --sdk-auth --role contributor --scopes "/subscriptions/$azSubscriptionId/resourceGroups/$azResourceGroupName" 

# Now print out $spCredential (it's a json snippet, fyi) and save it in your secrets.
