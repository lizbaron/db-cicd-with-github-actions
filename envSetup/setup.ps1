Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $projectName
);

$PSVersionTable;

$azResourceGroupName = "rg_" + $projectName;
$azServicePrincipalName = "sp_" + $projectName;
$azSecretsManagerName = "sm_" + $projectName;

$projectName;