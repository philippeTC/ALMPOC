# Importing common functions
. .\common\CrmSolution.Common.ps1
. .\common\Deployment.Common.ps1

# Defaulting to increased verbosity for manual execution
$oldverbose = $VerbosePreference
$VerbosePreference = "continue"

#region PARAMETERS

#Set Solution Version
$solutionVersion = "1.0.0.5"
$solutionXmlPath = ".\..\..\ALMPOC.CRM.Schema\Other"
$solutionPackageFolderPath = "D:\Development\Test\ALMPOC\ALMPOC.SolutionPackage\bin\Debug\PkgFolder"
$solutionPackageDLL = "D:\Development\Test\ALMPOC\ALMPOC.SolutionPackage\bin\Debug\ALMPOC.SolutionPackage.dll"

#Build Solution Parameters
$sourceCodePath = ".\..\..\"
$solutionFile = "ALMPOC.CRM.sln"
$configuration = "Debug"
$buildLogOutputPath = ".\"
$buildLogFile = "build.log"

#Deploy Solution Parameters
$serverUrl = "https://almpoc.crm4.dynamics.com"
$username = "philippe@almpoc.onmicrosoft.com"
$password = "Infront01"
$packageDeployerPath = "C:\infront\Dynamics365\SDK\Tools\PackageDeployer"

#endregion


#region Build and Prepare Solution

ApplyVersionToCrmSolution $solutionXmlPath $solutionVersion

Build-VisualStudioSolution -SourceCodePath $sourceCodePath -SolutionFile $solutionFile -Configuration $configuration -BuildLogOutputPath $buildLogOutputPath -BuildLogFile $buildLogFile

#endregion

#region Copy Package to Package Deployer

Copy-Item -Path $solutionPackageFolderPath -Recurse -Destination $packageDeployerPath -Force -Verbose
Copy-Item -Path $solutionPackageDLL -Recurse -Destination $packageDeployerPath -Force -Verbose

#endregion

#region DEPLOY SOLUTION

#region CREATE CRM CONNECTION
# check if required module is installed
if (-Not (Get-Module -ListAvailable -Name Microsoft.Xrm.Data.PowerShell))
{
  Write-Verbose "Initializing Micrsoft.Xrm.Data.Powershell module ..."
  Install-Module -Name Microsoft.Xrm.Data.PowerShell -Scope CurrentUser -ErrorAction SilentlyContinue -Force
}

# create CRM connection
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

if($isOnPremServer)
{
	Write-Verbose "Connecting to the OnPrem crm instance $serverUrl ..."
	$connectionState = Connect-CrmOnPremDiscovery -Credential $creds -ServerUrl $serverUrl
}
else
{
	Write-Verbose "Connecting to the Online crm instance $serverUrl ..."
	$connectionState = Connect-CrmOnline -Credential $creds -ServerUrl $serverUrl
}

# Make sure that the connection was successful, else stop the script.
if($connectionState.IsReady -eq $false)
{
	throw $connectionState.LastCrmError
}
#endregion

# install the necessary dll's (using Visual Studio Command prompt)
# cd C:\infront\Dynamics365\SDK\bin
# installutil Microsoft.Xrm.Tooling.CrmConnector.Powershell.dll
# installutil Microsoft.Xrm.Tooling.PackageDeployment.Powershell.dll


cd $packageDeployerPath\PowerShell

.\RegisterXRMTooling.ps1

Add-PSSnapin Microsoft.Xrm.Tooling.Connector
Add-PSSnapin Microsoft.Xrm.Tooling.PackageDeployment

# !!! when error on Crm-GetPackages: make sure VS package project has latest nuget crm libraries
$myPackages = Get-CrmPackages –PackageDirectory $packageDeployerPath
# Show all packages
$myPackages

# Import the package
Import-CrmPackage -CrmConnection $conn -PackageDirectory $packageDeployerPath -PackageName ALMPOC.SOLUTIONPACKAGE.dll -Verbose
#Import-CrmPackage –CrmConnection $CRMConn –PackageDirectory $packDir –PackageName $packName -Verbose;

#endregion