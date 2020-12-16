# db-cicd-with-github-actions

Demo code for "Level-Up Your CI/CD Game With k8s and GitHub to Avoid Database Disasters" session

## Setup AKS with Windows Node Pool
- https://docs.microsoft.com/en-us/azure/aks/windows-container-cli
- https://docs.microsoft.com/en-us/azure/aks/windows-container-powershell

## Setup Windows Docker Containers
- https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/manage-windows-dockerfile?context=/azure/aks/context/aks-context
- https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/optimize-windowInstall-AzAksKubectls-dockerfile?context=/azure/aks/context/aks-context

## Creates AKS -- (https://docs.microsoft.com/en-us/azure/aks/windows-container-powershell)
### Create an AKS cluster
$Password = Read-Host -Prompt 'Please enter your password' -AsSecureString
New-AzAKS -ResourceGroupName myResourceGroup -Name myAKSCluster -NodeCount 1 -KubernetesVersion 1.16.7 -NetworkPlugin azure -NodeVmSetType VirtualMachineScaleSets -WindowsProfileAdminUserName akswinuser -WindowsProfileAdminUserPassword $Password
### Add a Windows Server node pool
New-AzAksNodePool -ResourceGroupName myResourceGroup -ClusterName myAKSCluster -OsType Windows -Name npwin -KubernetesVersion 1.16.7
### Connect kubectl to the cluster
Install-AzAksKubectl
Import-AzAksCredential -ResourceGroupName myResourceGroup -Name myAKSCluster
### Try out kubectl
kubectl get nodes
