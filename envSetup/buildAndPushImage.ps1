Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$repoURL,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$commitId,
    $debugOnString="false"
);

$debugOn = ($debugOnString -eq "true");
if ($debugOn) {
    $DebugPreference = "Continue";
}

Set-ExecutionPolicy Bypass -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) ;
choco feature disable --name showDownloadProgress ;

choco install git --force --force-dependencies -y;

& 'C:\Program Files\Git\cmd\git.exe' clone $repoURL sourceRepo ;
cd sourceRepo ;
& 'C:\Program Files\Git\cmd\git.exe' checkout $commitId ; 

Get-ChildItem -Recurse -Path ./sourceRepo ;
