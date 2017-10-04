param(
	[Parameter(Mandatory=$true, Position=1)]
	[string]$serverUrl,
	[Parameter(Mandatory=$true, Position=2)]
	[string]$username,
	[Parameter(Mandatory=$true, Position=3)]
	[string]$password,
	[Parameter(Mandatory=$false)]
	[switch]$isOnPremServer,
	[Parameter(Mandatory=$false, Position=4)]
	[string]$dataFilePath
)

if (-Not (Get-Module -ListAvailable -Name Microsoft.Xrm.Data.PowerShell))
{
  Write-Verbose "Initializing Micrsoft.Xrm.Data.Powershell module ..."
  Install-Module -Name Microsoft.Xrm.Data.PowerShell -Scope CurrentUser -ErrorAction SilentlyContinue -Force
}

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

if($isOnPremServer)
{
	Write-Verbose "Connecting to OnPrem CRM instance $serverUrl ..."
	$connectionState = Connect-CrmOnPremDiscovery -Credential $creds -ServerUrl $serverUrl
}
else
{
	Write-Verbose "Connecting to Online CRM instance $serverUrl ..."
	$connectionState = Connect-CrmOnline -Credential $creds -ServerUrl $serverUrl
}

# Make sure that the connection was successful, else stop the script.
if($connectionState.IsReady -eq $false)
{
	throw $connectionState.LastCrmError
}

# Start Exporting Data
# ********************

# Retrieve NACE codes
$EntityLogicalName = "new_nacecode" #The logical name of the entity of the type of records to export
$FieldsToExport = @("new_nacecodeid", "new_name", "new_code") #The schema names of the attributes to export
$FetchXml = "" #Leave this empty to use a default fetchxml that takes all attributes and doesn't use any filter

Write-Output ('Begin exporting {0}' -f $EntityLogicalName) 
$recordCount = Export-ReferenceDataByFetchXml -entityLogicalName $EntityLogicalName -fieldsToExport $FieldsToExport -fetchXml $FetchXml -outputFile $dataFilePath\$EntityLogicalName\data.csv
Write-Output ('Done exporting {0} records' -f $recordCount) 

# Retrieve Countries
$EntityLogicalName = "new_country" #The logical name of the entity of the type of records to export
$FieldsToExport = @("new_countryid", "new_name", "new_iso") #The schema names of the attributes to export
$FetchXml = "" #Leave this empty to use a default fetchxml that takes all attributes and doesn't use any filter

Write-Output ('Begin exporting {0}' -f $EntityLogicalName) 
$recordCount = Export-ReferenceDataByFetchXml -entityLogicalName $EntityLogicalName -fieldsToExport $FieldsToExport -fetchXml $FetchXml -outputFile $dataFilePath\$EntityLogicalName\data.csv
Write-Output ('Done exporting {0} records' -f $recordCount) 
