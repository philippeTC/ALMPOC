<#
  .SYNOPSIS
    Manually deploy the CRM Solutions to the remote CRM servers.
  .DESCRIPTION
    Manually deploy the CRM solution to the configured remote CRM servers.
	.NOTES
		Author: Shane Carvalho
		Version: generator-nullfactory-xrm@1.4.0
	.LINK
		https://nullfactory.net
#>

# Importing common functions
. .\CrmSolution.Common.ps1

# Defaulting to increased verbosity for manual execution
$oldverbose = $VerbosePreference
$VerbosePreference = "continue"

Write-Host "Attempting to deploy solution(s)..."
try
{
  .\Deploy-CrmSolution.ps1 `
    -serverUrl "https://almpochanss.crm4.dynamics.com" `
    -username (Get-CrmUsername "ALMPOC.CRM.Schema") `
    -password (Get-CrmPassword "ALMPOC.CRM.Schema") `
    -solutionName "ALMPOC.CRM.Schema" `
    -publishChanges `
    -activatePlugins

  # Include new entry for each CRM solution to be released manually

  # .\Deploy-CrmSolution.ps1 `
  #   -serverUrl "http://servername/secondary" `
  #   -username (GetUsername "env_secondary_username_key") `
  #   -password (GetPassword "env_secondary_password_key") `
  #   -solutionName "secondary" `
  #   -publishChanges `
  #   -activatePlugins

  Write-Host "Deployment(s) complete." -ForegroundColor Green
}
finally
{
	# Reset the verbosity to original level
	$VerbosePreference = $oldverbose
}
