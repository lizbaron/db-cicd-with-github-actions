Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$mssqlVersion,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$acrURL, # eg. crn1234567890.azurecr.io
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][SecureString]$azSpCreds,
    $debugOnString="false"
);

$debugOn = ($debugOnString -eq "true");
if ($debugOn) {
    $DebugPreference = "Continue";
}

$azSpCredsConverted = ConvertFrom-SecureString -SecureString $azSpCreds -AsPlainText;
$decodedCreds = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("$azSpCredsConverted"));
$decodedCredsAsHash = (ConvertFrom-Json -InputObject $decodedCreds -AsHashtable) ;

cd sourceRepo;

docker login $acrURL --username $decodedCredsAsHash.clientId --password $decodedCredsAsHash.clientSecret

docker build . --file .\$mssqlVersion\Dockerfile --isolation=process -t $acrURL/mssql:$mssqlVersion

docker push $acrURL/$mssqlVersion
