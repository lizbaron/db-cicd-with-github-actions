Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $projectName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $azServicePrincipalObjectId,
    [Parameter(Mandatory=$false)][Switch] $debugOn
);

# https://activedirectoryfaq.com/2017/08/creating-individual-random-passwords/
function Get-RandomCharacters($length, $characters) { 
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $private:ofs="" 
    return [String]$characters[$random]
}

function Get-MD5HashOfString($string) {
    $stringAsStream = [System.IO.MemoryStream]::new();
    $writer = [System.IO.StreamWriter]::new($stringAsStream);
    $writer.write($string);
    $writer.Flush();
    $stringAsStream.Position = 0;
    $hashedString = (Get-FileHash -InputStream $stringAsStream).Hash;
    return [string]$hashedString;
}

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
if ($debugOn) {
    $DebugPreference = "Continue"
}

$azResourceGroupName = "rg_" + $projectName;
$region = (Get-AzResourceGroup -Name $azResourceGroupName).Location
$projectNameHash = (Get-MD5HashOfString($azSecretsManagerName)).Substring(0,10);
$azSecretsManagerName = "sm-" + $projectNameHash;
$aksClusterName = "aks-" + $projectNameHash;
$containerRegistryName = ("crn-" + $projectNameHash).Replace('-','');
$aksWinUser = "aksWinUser-" + $projectNameHash;
$aksWinNodePoolName = "aksWinNodePool-" + $projectNameHash;

Write-Debug ("Project Name: {0}" -f "$projectName"); 
Write-Debug ("Region: {0}" -f "$region"); 
Write-Debug ("Resource Group Name: {0}" -f "$azResourceGroupName"); 
Write-Debug ("Secrets Manager Name: {0}" -f "$azSecretsManagerName"); 
Write-Debug ("AKS Cluster Name: {0}" -f "$aksClusterName"); 
Write-Debug ("Container Registry Name: {0}" -f "$containerRegistryName"); 
Write-Debug ("AKS Win User Name: {0}" -f "$aksWinUser"); 
Write-Debug ("AKS Win Node Pool Name: {0}" -f "$aksWinNodePoolName"); 

# Set up Secrets Manager on Azure (AKV), if the Secrets Manager doesn't already exists
$smExists = Get-AzKeyVault -VaultName "$azSecretsManagerName"
if ($null -eq $smExists) {
    New-AzKeyVault -VaultName "$azSecretsManagerName" -ResourceGroupName "$azResourceGroupName" -Location "$region"
}

# The Azure Key Vault RBAC is two separate levels, management and data. The Contributor role assigned above to the azure service principal as part of manualPrep.ps1 is for the management level. Additional permissions are required to manipulate the data level. (https://docs.microsoft.com/en-us/azure/key-vault/general/overview-security)
Set-AzKeyVaultAccessPolicy -VaultName "$azSecretsManagerName" -ObjectId $azServicePrincipalObjectId -PermissionsToSecrets Set

$aksPassword = ConvertTo-SecureString -String (Get-RandomCharacters -length 40 -characters 'abcdefghiklmnoprstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ') -AsPlainText -Force

Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksPassword' -SecretValue $aksPassword;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'projectName' -SecretValue (ConvertTo-SecureString -String $projectName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'region' -SecretValue (ConvertTo-SecureString -String $region -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'azResourceGroupName' -SecretValue (ConvertTo-SecureString -String $azResourceGroupName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'azSecretsManagerName' -SecretValue (ConvertTo-SecureString -String $azSecretsManagerName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksClusterName' -SecretValue (ConvertTo-SecureString -String $aksClusterName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'containerRegistryName' -SecretValue (ConvertTo-SecureString -String $containerRegistryName -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksWinUser' -SecretValue (ConvertTo-SecureString -String $aksWinUser -AsPlainText -Force);
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksWinNodePoolName' -SecretValue (ConvertTo-SecureString -String $aksWinNodePoolName -AsPlainText -Force);

# Create a Container Registry
$acrExists = $null;
try {
    $acrExists = Get-AzContainerRegistry -ResourceGroupName "$azResourceGroupName" -Name "$containerRegistryName";
}
catch [Microsoft.Rest.Azure.CloudException] {
    Write-Debug "ACR does not exist"
}

if ($null -eq $acrExists) {
    New-AzContainerRegistry -ResourceGroupName "$azResourceGroupName" -Name "$containerRegistryName" -Sku "Basic"
}

# Create a new AKS Cluster with a single linux node
New-AzAKS -ResourceGroupName "$azResourceGroupName" -Name "$aksClusterName" -NodeCount 1 -NetworkPlugin azure -NodeVmSetType VirtualMachineScaleSets -WindowsProfileAdminUserName "$aksWinUser" -WindowsProfileAdminUserPassword "$aksPassword"

# Add a Windows Server node pool to our existing cluster
New-AzAksNodePool -ResourceGroupName "$azResourceGroupName" -ClusterName "$aksClusterName" -OsType Windows -Name "$aksWinNodePoolName" -KubernetesVersion 1.16.7

