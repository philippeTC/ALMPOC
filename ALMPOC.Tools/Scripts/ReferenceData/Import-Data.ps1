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

# Start Importing Data
Write-Verbose "Importing data from '$dataFilePath' ..."
Write-Verbose "Importing schema from '$dataSchemaFilePath' ..."

 $xmlfileEntities = get-content $dataFilePath'' 
 $xmlfileDataSchema = get-content $dataSchemaFilePath 
 $entitiesToImport = ([xml]$xmlfileEntities).entities  
 $entitiesSchema = ([xml]$xmlfileDataSchema).entities  
  
 $entitiesToImport.entity|%{ 
   #bulk create records 
    $entityName = $_.name 
    #get entity schema from data_schema.xml 
    $entitySchema = $entitiesSchema.entity|?{$_.name -eq  $entityName} 
 
     $_.records.record|%{ 
       $entity = New-Object Microsoft.Xrm.Sdk.Entity($entityName) 
       $entity.Id = [Guid]::Parse($_.id) 
       $hash = $null 
       $hash = @{} 
        #$hash.Add("Id",$entity.Id) 
       $_.field|%{ 
         $fieldAttributes = $_; 
         #find field type from Schema XML file 
         $fieldSchema = $entitySchema.fields.field|?{$_.name -eq $fieldAttributes.Name} 
          
         $value = $null; 
 
        switch($fieldSchema.type) 
         { 
           "boolean" { 
                $value = [bool]::Parse($fieldAttributes.value) 
                break               
            } 
            "datetime" { 
                 $value = [DateTime]::ParseExact($fieldAttributes.value,"dd/MM/yyyy HH:mm:ss",[System.Globalization.CultureInfo]::InvariantCulture,[System.Globalization.DateTimeStyles]::None) 
                break 
            } 
            "number" { 
                $value = [int32]::Parse($fieldAttributes.value) 
                break 
            } 
            "decimal" { 
                $value = [decimal]::Parse($fieldAttributes.value) 
                break 
            } 
            "money" { 
                $value = New-Object -TypeName 'Microsoft.Xrm.Sdk.Money' -ArgumentList $fieldAttributes.value 
                break 
            } 
            "state" 
            { 
              $intAtt = [int32]::Parse($fieldAttributes.value); 
              $value = New-Object -TypeName  "Microsoft.Xrm.Sdk.OptionSetValue" -ArgumentList $intAtt 
               break 
            } 
            "status" 
            { 
              $intAtt = [int32]::Parse($fieldAttributes.value); 
              $value = New-Object -TypeName  "Microsoft.Xrm.Sdk.OptionSetValue" -ArgumentList $intAtt 
              break 
            } 
            "entityReference" { 
               if($fieldAttributes.lookupentityname) 
               { 
                if($fieldAttributes.lookupentity -eq "transactioncurrency") 
                { 
                 $currency = Get-CurrencyId -lookupentity $fieldAttributes.lookupentity -lookupvalue $fieldAttributes.lookupentityname 
                 $value = New-Object -TypeName  "Microsoft.Xrm.Sdk.EntityReference" -ArgumentList $fieldAttributes.lookupentity,$currency.Attributes["transactioncurrencyid"]; 
                } 
                elseif($fieldAttributes.lookupentity -eq "systemuser") 
                { 
                 # $value = New-Object -TypeName  "Microsoft.Xrm.Sdk.EntityReference" -ArgumentList $fieldAttributes.lookupentity,$fieldAttributes.value; 
                  $user = Get-SystemUserId -lookupentity $fieldAttributes.lookupentity -lookupvalue $fieldAttributes.lookupentityname 
                  if($user) 
                  { 
                    $value = New-Object -TypeName  "Microsoft.Xrm.Sdk.EntityReference" -ArgumentList $fieldAttributes.lookupentity,$user.Attributes["systemuserid"]; 
                  } 
                } 
                else 
                { 
                  $value = $fieldAttributes.value; 
                } 
                break 
             } 
            } 
            "guid" { 
               $value = [Guid]::Parse($fieldAttributes.value) 
                break 
            } 
            "optionsetvalue" { 
               $intAtt = [int32]::Parse($fieldAttributes.value); 
               $value = New-Object -TypeName  "Microsoft.Xrm.Sdk.OptionSetValue" -ArgumentList $intAtt 
                break 
            } 
            "string" { 
               $value = $fieldAttributes.value 
                break 
            } 
            default { 
               $value = $fieldAttributes.value 
                break 
            } 
         } 
         if($value) 
         { 
           $hash.Add($fieldAttributes.Name,$value); 
         } 
       } 
 
     $fields = New-Object string[] 1 
     $fields[0] = "*" 
     $record = $null 
     Write-Output ('Updating/creating "{0}" (Id = {1})...' -f $entityName, $entity.Id) 
     try 
     { 
		$record = Get-CrmRecord -conn $conn -EntityLogicalName $entityName  -Id $entity.Id -Fields $fields 
     } 
     catch 
     { 
		$record = $null; 
     } 
     if($record) 
     { 
		set-CrmRecord -conn $conn -EntityLogicalName $entityName -Fields $hash -Id $entity.Id  
     } 
     else 
     { 
		New-CrmRecord -conn $conn -EntityLogicalName $entityName -Fields $hash 
     } 
   } 
 } 

