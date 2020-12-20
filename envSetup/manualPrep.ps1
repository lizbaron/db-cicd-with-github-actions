$azSubscriptionId = "xxx-xxx-xxx"
$projectName = "db-cicd-with-github-actions"
$azResourceGroupName = "rg_" + $projectName
$azServicePrincipalName = "sp_" + $projectName

az ad sp create-for-rbac -n "$azServicePrincipalName" --role contributor --scopes "/subscriptions/$azSubscriptionId/resourceGroups/$azResourceGroupName"
