$azSubscriptionId = "xxx-xxx-xxx"
$projectName = "db-cicd-with-github-actions"
$azResourceGroupName = "rg_" + $projectName
$azServicePrincipalName = "sp_" + $projectName

$spCredential = az ad sp create-for-rbac -n "$azServicePrincipalName" --role contributor --scopes "/subscriptions/$azSubscriptionId/resourceGroups/$azResourceGroupName"

# Now print out $spCredential (it's a json snippet, fyi) and save it in your secrets.
