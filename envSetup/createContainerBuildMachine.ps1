#TODO: Install Git and Docker on the Win2019 Core machine
#TODO: Clone Repository
Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$projectName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$azSecretsManagerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$azResourceGroupName,
    [switch]$debugOn=$false
);

if ($debugOn) {
    $DebugPreference = "Continue";
}

Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";
Write-Debug ("Project Name: {0}" -f "$projectName"); 
Write-Debug ("Resource Group Name: {0}" -f "$azResourceGroupName"); 
Write-Debug ("Secrets Manager Name: {0}" -f "$azSecretsManagerName"); 
Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";

# Create Username and Password

Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'buildMachineFQDN' -SecretValue $buildMachineFQDN;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'buildMachineUser' -SecretValue $buildMachineUser;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'buildMachinePassword' -SecretValue $buildMachinePassword;
