# Importing common functions
. .\..\common\ReferenceData.Common.ps1

$crmOrg = New-Object `         
   -TypeName Microsoft.Xrm.Tooling.Connector.CrmServiceClient `         
   -ArgumentList ([System.Net.CredentialCache]::DefaultNetworkCredentials),             ([Microsoft.Xrm.Tooling.Connector.AuthenticationType]::AD) 
,            $serverName 
,            $serverPort 
,             $organizationName 
,             $False 
,            $False 
,           ([Microsoft.Xrm.Sdk.Discovery.OrganizationDetail]$null) 
$dataFilePath =  "..\..\..\ALMPOC.CRM.Data\new_nacecode_data.zip" 
$dataSchemaFilePath = "..\..\..\ALMPOC.CRM.Data\new_nacecode_schema.xml" 
Write-Output "Begin import of configuration data..." 
Import-ConfigData -dataFilePath $dataFilePath -dataSchemaFilePath $dataSchemaFilePath -crmOrg $crmOrg 
Write-Output "End import of configuration data..."