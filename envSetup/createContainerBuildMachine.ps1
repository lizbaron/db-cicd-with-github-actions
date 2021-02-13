Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$projectName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$azSecretsManagerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$azResourceGroupName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$repoURL,
    [ValidateNotNullOrEmpty()][string]$azVMSize = "Standard_D2s_v3",
    [ValidateNotNullOrEmpty()][string]$azVMName = "Win2019Core",
    [switch]$debugOn=$false
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
    return [String]$hashedString;
}

if ($debugOn) {
    $DebugPreference = "Continue";
}

Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";
Write-Debug ("Project Name: {0}" -f "$projectName"); 
Write-Debug ("Resource Group Name: {0}" -f "$azResourceGroupName"); 
Write-Debug ("Secrets Manager Name: {0}" -f "$azSecretsManagerName"); 
Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";

# Create Username and Password

# ^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%\^&\*\(\)])[a-zA-Z\d!@#$%\^&\*\(\)]***12,123***$
$part1 = (Get-RandomCharacters -length 10 -characters 'abcdefghiklmnoprstuvwxyz');
$part2 = (Get-RandomCharacters -length 10 -characters '1234567890');
$part3 = (Get-RandomCharacters -length 10 -characters 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
$part4 = (Get-RandomCharacters -length 10 -characters '!#$%^&*');
$allParts = -join ((-join ($part1,$part2,$part3,$part4)).ToCharArray() | Get-Random -Shuffle);
$buildMachinePassword = ConvertTo-SecureString -String "$allParts" -AsPlainText -Force;

$part1 = (Get-RandomCharacters -length 10 -characters 'abcdefghiklmnoprstuvwxyz');
$part2 = (Get-RandomCharacters -length 5 -characters '1234567890');
$buildMachineUserName = "User_" + (-join ((-join ($part1,$part2)).ToCharArray() | Get-Random -Shuffle));
$secretBuildMachineUserName = ConvertTo-SecureString -String "$buildMachineUserName" -AsPlainText -Force;

Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";
Write-Debug ("buildMachineUserName: {0}" -f "$buildMachineUserName"); 
Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";

$LocationName = (Get-AzResourceGroup -Name $azResourceGroupName).location;
$ComputerName = $azVMName;

$NetworkName = "MyNet";
$NICName = "MyNIC";
$SubnetName = "MySubnet";
$SubnetAddressPrefix = "10.0.0.0/24";
$VnetAddressPrefix = "10.0.0.0/16";

$SingleSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix;
$Vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $azResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet;
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $azResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id;

$Credential = New-Object System.Management.Automation.PSCredential ($buildMachineUserName, $buildMachinePassword);

$VirtualMachine = New-AzVMConfig -VMName $azVMName -VMSize $azVMSize;
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate;
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id;
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter-Core-with-Containers' -Version latest;

$azVM = New-AzVM -ResourceGroupName $azResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose;

Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";
Write-Debug ("azVM"); 
Write-Debug ($azVM | Format-Table | Out-String);
Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";
Write-Debug ("Get-ChildItem"); 
Write-Debug (Get-ChildItem -Recurse -Path . | Format-Table | Out-String);
Write-Debug "✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ✨   ";

$setupBuildMachinePath = (Split-Path $MyInvocation.MyCommand.Path -Parent) + '\testBuildMachine.ps1';
Invoke-AzVMRunCommand -ResourceGroupName $azResourceGroupName -VMName $azVMName -CommandId 'RunPowerShellScript' -ScriptPath $setupBuildMachinePath -Parameter @{repoURL = "$repoURL"; debugOnString = "$debugOn"}


# Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'buildMachineFQDN' -SecretValue $buildMachineFQDN;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'buildMachineUser' -SecretValue $secretBuildMachineUserName;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'buildMachinePassword' -SecretValue $buildMachinePassword;
