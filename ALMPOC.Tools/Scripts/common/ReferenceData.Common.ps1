function Get-CurrencyId 
{ 
    PARAM 
    ( 
        [string]$lookupentity 
        ,[string]$lookupentityname 
    ) 
 
    $query = New-Object -TypeName Microsoft.Xrm.Sdk.Query.QueryExpression -ArgumentList "$LookUpentity"; 
    $query.Criteria.AddCondition("currencyname", [Microsoft.Xrm.Sdk.Query.ConditionOperator]::Equal, $lookupentityname); 
    $query.ColumnSet.AddColumn("transactioncurrencyid"); 
    $query.ColumnSet.AddColumn("currencyname"); 
    $results = $crmOrgProxy.RetrieveMultiple($query); 
    $records = $results.Entities; 
    if ($records.Count -eq 1) 
    { 
        return $records[0] 
    } 
 
    Write-Host -ForegroundColor Red "Currency entity with name '$lookupentityname' not found" 
    return $null; 
} 
 
function Get-SystemUserId 
{ 
    PARAM 
    ( 
        [string]$lookupentity 
        ,[string]$lookupentityname 
    ) 
 
    $query = New-Object -TypeName Microsoft.Xrm.Sdk.Query.QueryExpression -ArgumentList "$LookUpentity"; 
    $query.Criteria.AddCondition("fullname", [Microsoft.Xrm.Sdk.Query.ConditionOperator]::Equal, $lookupentityname); 
    $query.ColumnSet.AddColumn("systemuserid"); 
    $query.ColumnSet.AddColumn("fullname"); 
    $results = $crmOrgProxy.RetrieveMultiple($query); 
    $records = $results.Entities; 
    if ($records.Count -eq 1) 
    { 
        return $records[0] 
    } 
 
    Write-Warning "User entity with name ' $lookupentityname' not found" 
    return $null; 
} 
 
 
function Import-ConfigData 
{ 
  PARAM 
    ( 
        [string]$dataFilePath 
        ,[string]$dataSchemaFilePath 
        ,[Microsoft.Xrm.Tooling.Connector.CrmServiceClient]$crmOrg 
    ) 
 
 $xmlfileEntities = get-content $dataFilePath 
 $xmlfileDataSchema = get-content $dataSchemaFilePath 
 $entitiesToImport = ([xml]$xmlfileEntities).entities  
 $entitiesSchema = ([xml]$xmlfileDataSchema).entities  
 
 $crmOrgProxy = $crmOrg.OrganizationServiceProxy 
 
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
                 $currency = Get-CurrencyId -lookupentity $fieldAttributes.lookupentity -lookupentityname $fieldAttributes.lookupentityname 
                 $value = New-Object -TypeName  "Microsoft.Xrm.Sdk.EntityReference" -ArgumentList $fieldAttributes.lookupentity,$currency.Attributes["transactioncurrencyid"]; 
                } 
                elseif($fieldAttributes.lookupentity -eq "systemuser") 
                { 
                 # $value = New-Object -TypeName  "Microsoft.Xrm.Sdk.EntityReference" -ArgumentList $fieldAttributes.lookupentity,$fieldAttributes.value; 
                  $user = Get-SystemUserId -lookupentity $fieldAttributes.lookupentity -lookupentityname $fieldAttributes.lookupentityname 
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
      $record = Get-CrmRecord -conn $crmOrg -EntityLogicalName $entityName  -Id $entity.Id -Fields $fields 
     } 
     catch 
     { 
      $record = $null; 
     } 
     if($record) 
     { 
      set-CrmRecord -conn $crmOrg -EntityLogicalName $entityName -Fields $hash -Id $entity.Id  
     } 
     else 
     { 
      New-CrmRecord -conn $crmOrg -EntityLogicalName $entityName -Fields $hash 
     } 
   } 
 } 
}