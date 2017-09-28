
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