
 function Get-CurrencyId 
{ 
    PARAM 
    ( 
        [string]$lookupentity 
        ,[string]$lookupvalue 
    ) 

	$results = Get-CrmRecords -conn $conn -EntityLogicalName $lookupentity -FilterAttribute currencyname -FilterOperator "eq" -FilterValue $lookupvalue -Fields transactioncurrencyid,currencyname
    $records = $results.CrmRecords; 
    if ($records.Count -eq 1) 
    { 
        return $records[0] 
    } 
 
    Write-Host -ForegroundColor Red "Currency with name '$lookupvalue' not found" 
    return $null; 
} 
 
function Get-SystemUserId 
{ 
    PARAM 
    ( 
        [string]$lookupentity 
        ,[string]$lookupvalue 
    ) 
 
	$results = Get-CrmRecords -conn $conn -EntityLogicalName $lookupentity -FilterAttribute currencyname -FilterOperator "eq" -FilterValue $lookupvalue -Fields transactioncurrencyid,currencyname
    $records = $results.CrmRecords; 
    if ($records.Count -eq 1) 
    { 
        return $records[0] 
    } 
 
    Write-Warning "User with name ' $lookupvalue' not found" 
    return $null; 
} 

#function Test-Function
#{ 
#    PARAM 
#    ( 
#        [string]$param1
#	)

#	Write-Verbose "-param1: "$param1 

#	return 0;
#}

function Test-Function 
{ 
    PARAM 
    ( 
        [string]$lookupentity 
        ,[string]$lookupvalue 
    ) 

	Write-Verbose "-lookupentity: $lookupentity" 
	Write-Verbose "-lookupvalue: $lookupvalue" 
	
    return 0; 
}

function Export-ReferenceDataByFetchXml
{ 
    PARAM 
    ( 
        [string]$entityLogicalName
        ,[string[]]$fieldsToExport
		,[string]$fetchXml
		,[string]$outputFile
    ) 
	
	Write-Verbose "-entityLogicalName: $entityLogicalName"
	Write-Verbose "-fieldsToExport: $fieldsToExport"
	Write-Verbose "-fetchXml: $fetchXml"
	Write-Verbose "-outputFile: $outputFile"

	# use defaul xml when none provided
	if ([string]::IsNullOrEmpty($fetchXml))
	{
		$fetchXml = @"
		<fetch mapping="logical" version="1.0"><entity name="$entityLogicalName"><all-attributes/></entity></fetch>
"@
	}

	# check if output folder exists
	$outputFilePath = Split-Path -Path $outputFile
	if(!(test-path $outputFilePath))
	{
		Write-Verbose "Path '$outputFilePath' does not exist ..."
		$item = New-Item -ItemType Directory -Force -Path $outputFilePath
		Write-Verbose "Path '$outputFilePath' created successfully"
	}

	# Retrieve and export records
	Write-Verbose "Executing fetchXml: $fetchXml"
	$result = Get-CrmRecordsByFetch -Fetch $fetchXml -conn $conn -AllRows
	$result.CrmRecords | Select -Property $fieldsToExport | Export-Csv -Encoding UTF8 -Path $outputFile -Delimiter "`t" -NoTypeInformation

	return $result.Count;
}