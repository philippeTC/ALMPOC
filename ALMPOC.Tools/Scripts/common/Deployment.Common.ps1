<#
  .SYNOPSIS
    Recursively finds a list of files and uses a pattern to match and replace matches with a specified version number.
  .DESCRIPTION
    Recursively finds a list of files within a folder and uses a regular expression pattern to match and replace it with a specified version number.
	.NOTES
		Author: Shane Carvalho
		Version: generator-nullfactory-xrm@1.4.0
	.LINK
		https://nullfactory.net
	.PARAMETER BuildSourcePath
    The root folder to search.
  .PARAMETER versionFile
    The pattern of file to be searched.
  .PARAMETER regexPattern
    The regex pattern to be searched.
  .PARAMETER finalVersion
    The new version number.
  .PARAMETER encoding
    The optional encoding. Common encoding values include ASCII, Unicode, UTF8, Default. Default uses the encoding of the system's current ANSI code page.
  .EXAMPLE
    ReplaceVersion ".\SourceRootFolder" "*AssemblyInfo.cs" "\d+\.\d+\.\d+\.\d+" "1.3.0"
    Gets a list of all files starting with "*AssemblyInfo.cs" within the folder "SourceRootFolder". Within these files it attempts to match all instances of a version number ex. 0.0.0.0 and replace it with the new version number.
#>
function ReplaceVersion([string]$BuildSourcePath, [string] $versionFile, [string] $regexPattern, [string]$finalVersion, [string]$encoding='Default')
{
  [bool]$output = $false
  $files = Get-ChildItem $BuildSourcePath -recurse -include $versionFile

  if ($files)
  {
    $output = $true
    Write-Verbose "Attempting to apply $finalVersion to $($files.count) files in $BuildSourcePath\**\$versionFile ..."

    foreach ($file in $files)
    {
      $filecontent = Get-Content($file)
      attrib $file -r
      $filecontent -replace $regexPattern, $finalVersion | Out-File $file -encoding $encoding
      Write-Host "$finalVersion version successfully applied to $file with encoding $encoding" -ForegroundColor Green
    }
  }
  return $output
}

<#
  .SYNOPSIS
    Applies a specified version number to a list of file matching a pattern.
  .PARAMETER BuildSourcePath
    The root folder containing the source files.
  .PARAMETER BuildBuildNumber
    The new build number.
  .EXAMPLE
    ApplyVersionToAssemblies ".\RootFolder" "0.1.2"
#>
function ApplyVersionToAssemblies
{
  [CmdletBinding()]
  Param
  (
    [parameter(Position=0, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$BuildSourcePath,
    [parameter(Position=1, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$BuildBuildNumber
  )

  $isSuccess =  (ReplaceVersion $BuildSourcePath "*AssemblyInfo.cs" "\d+\.\d+\.\d+\.\d+" $BuildBuildNumber)

  if ($isSuccess)
  {
    Write-Warning "No files found at $BuildSourcePath."
  }
}

<#
  .SYNOPSIS
    Applies a specified version number to a CRM solution.
  .PARAMETER BuildSourcePath
    The root folder containing the extracted (via solutio packager) CRM Solution.
  .PARAMETER BuildBuildNumber
    The new build number.
  .EXAMPLE
    ApplyVersionToCrmSolution ".\RootFolder" "0.1.2"
#>
function ApplyVersionToCrmSolution
{
  [CmdletBinding()]
  Param
  (
    [parameter(Position=0, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$BuildSourcePath,
    [parameter(Position=1, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$BuildBuildNumber
  )

  $isSuccess = (ReplaceVersion $BuildSourcePath "Solution.xml" '<Version>[\s\S]*?<\/Version>' "<Version>$BuildBuildNumber</Version>" "utf8")

  if ($isSuccess -eq $false)
  {
    Write-Warning "No files found at $BuildSourcePath."
  }
}

function Build-VisualStudioSolution            
{            
    param            
    (            
        [parameter(Mandatory=$false)]            
        [ValidateNotNullOrEmpty()]             
        [String] $SourceCodePath = "./../..",            
            
        [parameter(Mandatory=$false)]            
        [ValidateNotNullOrEmpty()]             
        [String] $SolutionFile,            
                    
        [parameter(Mandatory=$false)]            
        [ValidateNotNullOrEmpty()]             
        [String] $Configuration = "Debug",            
                    
        [parameter(Mandatory=$false)]            
        [ValidateNotNullOrEmpty()]             
        [Boolean] $AutoLaunchBuildLog = $false,            
            
        [parameter(Mandatory=$false)]            
        [ValidateNotNullOrEmpty()]             
        [Switch] $MsBuildHelp,            
                    
        [parameter(Mandatory=$false)]            
        [ValidateNotNullOrEmpty()]             
        [Switch] $CleanFirst,            
                    
        [ValidateNotNullOrEmpty()]             
        [string] $BuildLogFile,            
               
		[ValidateNotNullOrEmpty()]                  
        [string] $BuildLogOutputPath = $env:userprofile + "\Desktop\"            
    )            
                
    process            
    {            
        # Local Variables            
        #$MsBuild = $env:systemroot + "\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe";            
         $MsBuild = ${env:ProgramFiles(x86)} + "\MSBuild\14.0\Bin\MSBuild.exe"; 
		        
        # Caller requested MsBuild Help?            
        if($MsBuildHelp)            
        {            
                $BuildArgs = @{            
                    FilePath = $MsBuild            
                    ArgumentList = "/help"            
                    Wait = $true            
                    RedirectStandardOutput = "C:\MsBuildHelp.txt"            
                }            
            
                # Get the help info and show            
                Start-Process @BuildArgs            
                Start-Process -verb Open "C:\MsBuildHelp.txt";            
        }            
        else            
        {            
            # Local Variables            
            $SlnFilePath = $SourceCodePath + $SolutionFile;            
            $SlnFileParts = $SolutionFile.Split("\");            
            $SlnFileName = $SlnFileParts[$SlnFileParts.Length - 1];            
            $BuildLog = $BuildLogOutputPath + $BuildLogFile            
            $bOk = $true;            
                        
            try            
            {            
                # Clear first?            
                if($CleanFirst)            
                {            
                    # Display Progress            
                    Write-Progress -Id 20275 -Activity $SlnFileName  -Status "Cleaning..." -PercentComplete 10;            
                            
                    $BuildArgs = @{            
                        FilePath = $MsBuild            
                        ArgumentList = $SlnFilePath, "/t:clean", ("/p:Configuration=" + $Configuration), "/v:minimal"            
                        RedirectStandardOutput = $BuildLog            
                        Wait = $true            
                        #WindowStyle = "Hidden"            
                    }            
            
                    # Start the build            
                    Start-Process @BuildArgs #| Out-String -stream -width 1024 > $DebugBuildLogFile             
                                
                    # Display Progress            
                    Write-Progress -Id 20275 -Activity $SlnFileName  -Status "Done cleaning." -PercentComplete 50;            
                }            
            
                # Display Progress            
                Write-Progress -Id 20275 -Activity $SlnFileName  -Status "Building..." -PercentComplete 60;            
                            
                # Prepare the Args for the actual build            
                $BuildArgs = @{            
                    FilePath = $MsBuild            
                    ArgumentList = $SlnFilePath, "/t:rebuild", ("/p:Configuration=" + $Configuration), "/v:minimal"            
                    RedirectStandardOutput = $BuildLog            
                    Wait = $true            
                    #WindowStyle = "Hidden"            
                }            
            
                # Start the build            
                Start-Process @BuildArgs #| Out-String -stream -width 1024 > $DebugBuildLogFile             
                            
                # Display Progress            
                Write-Progress -Id 20275 -Activity $SlnFileName  -Status "Done building." -PercentComplete 100;            
            }            
            catch            
            {            
                $bOk = $false;            
                Write-Error ("Unexpect error occured while building " + $SlnFileParts[$SlnFileParts.Length - 1] + ": " + $_.Message);            
            }            
                        
            # All good so far?            
            if($bOk)            
            {            
                #Show projects which where built in the solution            
                #Select-String -Path $BuildLog -Pattern "Done building project" -SimpleMatch            
                            
                # Show if build succeeded or failed...            
                $successes = Select-String -Path $BuildLog -Pattern "Build succeeded." -SimpleMatch            
                $failures = Select-String -Path $BuildLog -Pattern "Build failed." -SimpleMatch            
                            
                if($failures -ne $null)            
                {            
                    Write-Warning ($SlnFileName + ": A build failure occured. Please check the build log $BuildLog for details.");            
                }            
                            
                # Show the build log...            
                if($AutoLaunchBuildLog)            
                {            
                    Start-Process -verb "Open" $BuildLog;            
                }            
            }            
        }            
    }            
                
    <#
        .SYNOPSIS
        Executes the v2.0.50727\MSBuild.exe tool against the specified Visual Studio solution file.
        
        .Description
        
        .PARAMETER SourceCodePath
        The source code root directory. $SolutionFile can be relative to this directory. 
        
        .PARAMETER SolutionFile
        The relative path and filename of the Visual Studio solution file.
        
        .PARAMETER Configuration
        The project configuration to build within the solution file. Default is "Debug".
        
        .PARAMETER AutoLaunchBuildLog
        If true, the build log will be launched into the default viewer. Default is false.
        
        .PARAMETER MsBuildHelp
        If set, this function will run MsBuild requesting the help listing.
        
        .PARAMETER CleanFirst
        If set, this switch will cause the function to first run MsBuild as a "clean" operation, before executing the build.
        
        .PARAMETER BuildLogFile
        The name of the file which will contain the build log after the build completes.
        
        .PARAMETER BuildLogOutputPath
        The full path to the output folder where build log files will be placed. Defaults to the current user's desktop.
        
        .EXAMPLE
        
        .LINK
        http://stackoverflow.com/questions/2560652/why-does-powershell-fail-to-build-my-net-solutions-file-is-being-used-by-anot
        http://geekswithblogs.net/dwdii
        
        .NOTES
        Name:   Build-VisualStudioSolution
        Author: Daniel Dittenhafer
    #>                
}