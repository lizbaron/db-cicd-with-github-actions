Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$repoURL,
    [switch]$debugOn=$false
);

if ($debugOn) {
    $DebugPreference = "Continue";
}

Set-ExecutionPolicy Bypass -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) ;

choco install git;

git clone $repoURL sourceRepo ;

Get-ChildItem -Recurse -Path ./sourceRepo ;
