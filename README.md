# db-cicd-with-github-actions

Demo code for "Level-Up Your CI/CD Game With k8s and GitHub to Avoid Database Disasters" session
With gratitude this session heavily borrows from prior art created with Sreeja Pullagura (@sreejaptfa) and Andy Leonard (@aleonard763), found on the the Teach For America github repository here: https://github.com/teach-for-america/ssiscicd

## Goals
1. Create a database from a script or dacpac
1. Create isolated SQL Server instances on containers
1. Run tests for isolated environments in parallel

## Big Goals
1. multi-cloud - Azure, AWS, GCP
1. dacpac deployment

### Questions We Consider
- AKS v. ACI for Windows containers
- Namespaces on k8s
- Where are container images built?

### How to use
1. login to Azure
1. confirm which subscription you would like to use and that it is both "State"="Enabled" and "IsDefault"="True" `az account list -o table` 
1. switch to your desired subscription if not "IsDefault"="True" `az account set --subscription <YOURSUBSCRIPTIONID>`
1. confirm ^^^ `az account list -o table`
1. in Azure Cloud Shell
  1. make a "repos" directory and in that directory, clone this repository `git clone <THISREPO>` (TODO: figure out if markdown will allow self-reference to current repo)
  1. run `envSetup/manualPrep.ps1 -projectName <YOURPROJECTNAME>`
1. follow the instructions to save the json snippet to your GitHub Secrets with the correct name
1. in the GitHub repo, run the "CI/CD Environment Setup" workflow with <YOURPROJECTNAME> as the Project Name parameter

### TODO
- [ ] GitHub action to build sql server images
- [ ] Automate adding images to the new ACR
- [ ] Automate attaching ACR to AKS
- [x] Automate updating deployment to refer to the correct ACR 
```
      containers:
      - name: mssql2017-db
        image: <REPLACEME>
```


### Required Resources

- Key Management: Azure Key Vault, GCP Key Management Services, AWS Key Management Services
- Container Registry: Azure Container Registry, GCP Container Registry, AWS Elastic Container Registry
- Artifact Repository:
- Pipeline orchestration: Jenkins, GCP CloudBuild, CircleCI, GitHub Actions

When working in Azure, remember to register all service providers in your subscription before automating.
```
az provider register --namespace 'Microsoft.KeyVault' 
az provider register --namespace 'Microsoft.ContainerRegistry' 
az provider register --namespace 'Microsoft.Kubernetes' 
```

## Azure
This is two separate pipelines: one to set up the environment, and one to run the CI/CD pipelines.

### Environment Setup Steps
#### Variables
- `$resourceGroupName`
- `$region`
- `$vaultName`


#### Create a Resource Group (https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroup?view=azps-5.2.0)
```
New-AzResourceGroup -Name "$resourceGroupName" -Location "$region" -Tag @{Department="tSQLtCI"; Ephemeral="True"} -Force|Out-String|Log-Output;
```

#### Create AKV -- (https://docs.microsoft.com/en-us/powershell/module/az.keyvault/new-azkeyvault?view=azps-5.2.0)
```
New-AzKeyVault -VaultName "$vaultName" -ResourceGroupName "$resourceGroupName" -Location "$region"
```

#### Add secrets to AKV (https://docs.microsoft.com/en-us/powershell/module/az.keyvault/set-azkeyvaultsecret?view=azps-5.2.0)
You will need to ensure that the service principal you use to do this work has the correct permissions assigned to update the Key Vault data (not just the AKV resource itself).
```
$Secret = ConvertTo-SecureString -String 'Password' -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName 'Contoso' -Name 'ITSecret' -SecretValue $Secret
```
- `$containerRegistryName`
- `$aksClusterName`
- `$aksPassword`  SecureString
- `$aksWinUser`  SecureString
- `$aksWinNodePoolName`  SecureString
- `$resourceGroupName`
- `$region`
- `$vaultName`

Maybe
- `$docker-server`
- `$docker-username`
- `$docker-password`
- `$docker-email`
- `$servicePrincipalURL`
- `$servicePrincipalPassword`
- `$ssiscicdTenantId`
- `$deploymentName` k8s pod
- `$serviceName` k8s
- `$port` mssql external
- `$targetPort` mmsql internal
- `$podName`
- `$ipAddress` fqdn
- `$saPassword`

#### Create ACR
```
New-AzContainerRegistry -ResourceGroupName "$resourceGroupName" -Name "$containerRegistryName" -Sku "Basic"
```

#### Setup AKS (https://docs.microsoft.com/en-us/azure/aks/windows-container-powershell)
To make this less cost prohibitive, turn on the startstoppreview feature. (https://docs.microsoft.com/en-us/azure/aks/start-stop-cluster)
- `az aks show --name $aksClusterName --resource-group $resourceGroupName --query 'agentPoolProfiles[].{Name:name, PowerState:powerState.code}'`

##### Docs - Windows Node Pool
- https://docs.microsoft.com/en-us/azure/aks/windows-container-cli
- https://docs.microsoft.com/en-us/azure/aks/windows-container-powershell

##### Docs - Setup Windows Docker Containers
- https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/manage-windows-dockerfile?context=/azure/aks/context/aks-context
- https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/optimize-windowInstall-AzAksKubectls-dockerfile?context=/azure/aks/context/aks-context
```
New-AzAKS -ResourceGroupName "$resourceGroupName" -Name "$aksClusterName" -NodeCount 1 -KubernetesVersion 1.16.7 -NetworkPlugin azure -NodeVmSetType VirtualMachineScaleSets -WindowsProfileAdminUserName "$aksWinUser" -WindowsProfileAdminUserPassword "$aksPassword"
```
Add a Windows Server node pool
```
New-AzAksNodePool -ResourceGroupName "$resourceGroupName" -ClusterName "$aksClusterName" -OsType Windows -Name "$aksWinNodePoolName" -KubernetesVersion 1.16.7
```
Connect kubectl to the cluster
```
Install-AzAksKubectl
Import-AzAksCredential -ResourceGroupName "$resourceGroupName" -Name "$aksClusterName"
```
Try out kubectl
```
kubectl get nodes
```

