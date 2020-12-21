Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $projectName
);

# https://activedirectoryfaq.com/2017/08/creating-individual-random-passwords/
function Get-RandomCharacters($length, $characters) { 
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $private:ofs="" 
    return [String]$characters[$random]
}

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

$region = (Get-AzResourceGroup -Name $azResourceGroupName).Location
$azResourceGroupName = "rg_" + $projectName;
$azSecretsManagerName = "sm_" + $projectName;
$aksClusterName = "aks_" + $projectName;
$containerRegistryName = "crn_" + $projectName;
$aksWinUser = "aksWinUser_" + (Get-RandomCharacters -length 10 -characters '1234567890')
$aksWinNodePoolName = "aksWinNodePool_" + (Get-RandomCharacters -length 10 -characters '1234567890')

Write-Debug ("Project Name: {0}" -f "$projectName"); 
Write-Debug ("Region: {0}" -f "$region"); 
Write-Debug ("Resource Group Name: {0}" -f "$azResourceGroupName"); 
Write-Debug ("Secrets Manager Name: {0}" -f "$azSecretsManagerName"); 
Write-Debug ("AKS Cluster Name: {0}" -f "$aksClusterName"); 
Write-Debug ("Container Registry Name: {0}" -f "$containerRegistryName"); 
Write-Debug ("AKS Win User Name: {0}" -f "$aksWinUser"); 
Write-Debug ("AKS Win Node Pool Name: {0}" -f "$aksWinNodePoolName"); 

# Set up Secrets Manager on Azure (AKV)
New-AzKeyVault -VaultName "$azSecretsManagerName" -ResourceGroupName "$azResourceGroupName" -Location "$region"

$aksPassword = ConvertTo-SecureString -String (Get-RandomCharacters -length 40 -characters 'abcdefghiklmnoprstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ') -AsPlainText -Force

Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksPassword' -SecretValue $aksPassword;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'projectName' -SecretValue $projectName;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'region' -SecretValue $region;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'azResourceGroupName' -SecretValue $azResourceGroupName;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'azSecretsManagerName' -SecretValue $azSecretsManagerName;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksClusterName' -SecretValue $aksClusterName;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'containerRegistryName' -SecretValue $containerRegistryName;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksWinUser' -SecretValue $aksWinUser;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'aksWinNodePoolName' -SecretValue $aksWinNodePoolName;

# Create a Container Registry
New-AzContainerRegistry -ResourceGroupName "$azResourceGroupName" -Name "$containerRegistryName" -Sku "Basic"

# Create a new AKS Cluster with a single linux node
New-AzAKS -ResourceGroupName "$resourceGroupName" -Name "$aksClusterName" -NodeCount 1 -KubernetesVersion 1.16.7 -NetworkPlugin azure -NodeVmSetType VirtualMachineScaleSets -WindowsProfileAdminUserName "$aksWinUser" -WindowsProfileAdminUserPassword "$aksPassword"

# Add a Windows Server node pool to our existing cluster
New-AzAksNodePool -ResourceGroupName "$resourceGroupName" -ClusterName "$aksClusterName" -OsType Windows -Name "$aksWinNodePoolName" -KubernetesVersion 1.16.7

