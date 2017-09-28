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
	[string]$dataFilePath,
 	[Parameter(Mandatory=$false, Position=5)]
    [string]$dataSchemaFilePath 
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
# Retrieve by FETCHXML Sample
$result = Get-CrmRecordsByFetch @"
    <fetch mapping="logical" version="1.0">
  <entity name="account">
    <attribute name="customertypecode" alias="customertypecode" />
    <attribute name="name" alias="company_name" />
    <attribute name="telephone1" alias="company_telephone1" />
    <attribute name="telephone2" alias="company_telephone2" />
    <attribute name="fax" alias="company_fax" />
    <attribute name="websiteurl" alias="company_url" />
    <link-entity name="contact" from="accountid" to="accountid" link-type="inner">
      <attribute name="lastname" alias="lastname" />
      <attribute name="firstname" alias="firstname" />
    </link-entity>
  </entity>
</fetch>
"@

$result.CrmRecords | Select -Property lastname, firstname, salutation, jobtitle| Export-Csv -Encoding UTF8 -Path C:\export.csv -Delimiter ";" 


# Normal Retrieve Sample

$EntityLogicalName = "account" #The logical name of the entity of the type of records to export
$FieldsToExport = "name","telephone1" #The schema names of the attributes to export
$OutputFile = "accounts.csv" #The filename of the output file

#Get all records of the selected type and pipe the output to Select-Object
(Get-CrmRecords -EntityLogicalName $EntityLogicalName -Fields $FieldsToExport -AllRows).CrmRecords |
    #Only include the attributes that are to be exported and pipe the result to Export-CSV
    Select-Object -Property $FieldsToExport |
    #Output the results to CSV-file
    Export-Csv -Path $OutputFile -Encoding Default -NoTypeInformation