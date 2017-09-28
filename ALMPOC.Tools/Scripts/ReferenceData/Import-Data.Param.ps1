# Importing common functions
. .\..\common\CrmSolution.Common.ps1
. .\..\common\ReferenceData.Common.ps1

# Defaulting to increased verbosity for manual execution
$oldverbose = $VerbosePreference
$VerbosePreference = "continue"

try
{
	Write-Output "Begin import of configuration data..." 
	
	.\Import-Data.ps1 `
    -serverUrl (Get-CrmDevOrgUrl "ALMPOC.CRM.Schema") `
    -username (Get-CrmUsername "ALMPOC.CRM.Schema") `
    -password (Get-CrmPassword "ALMPOC.CRM.Schema") `
	-dataFilePath "..\..\..\ALMPOC.CRM.Data\new_nacecode\data.xml" `
	-dataSchemaFilePath "..\..\..\ALMPOC.CRM.Data\new_nacecode\data_schema.xml"

	Write-Output "End import of configuration data..."
}
finally
{
	# Reset the verbosity to original level
	$VerbosePreference = $oldverbose
}