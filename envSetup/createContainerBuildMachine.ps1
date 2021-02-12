#TODO: Install Git and Docker on the Win2019 Core machine
#TODO: Clone Repository




Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'buildMachineFQDN' -SecretValue $buildMachineFQDN;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'buildMachineUser' -SecretValue $buildMachineUser;
Set-AzKeyVaultSecret -VaultName "$azSecretsManagerName" -Name 'buildMachinePassword' -SecretValue $buildMachinePassword;
