Set-StrictMode -Version 3.0

$ErrorActionPreference="Stop"
$VerbosePreference="SilentlyContinue"

$env:AzureDevopsProfileName="azdev-cli-build-deploy-repo"
$env:AzureDevOpsBuildDefinitionName="azdev-cli-build"
$env:AzureDevOpsProjectName="Public-Automation-Examples"

<#
.SYNOPSIS
Tests whether the environment is configured to talk to Azure DevOps.

This is not a 'real' Test- method in the PowerShell sense; silence is golden here and does not return true/false. 

.EXAMPLE
C:\PS> Test-BadAzureDevOpsContext
#>
function Test-BadAzureDevopsContext {
 
    [CmdletBinding()]
    PARAM 
    (
        [Parameter(Mandatory=$false)]
        [System.String]
        $AzureDevOpsProfileName = $env:AzureDevopsProfileName
    )
    PROCESS {

        Write-Verbose "AzureDevopsProfileName: $($AzureDevopsProfileName)"

        if(-NOT $AzureDevopsProfileName) {
            throw "ERROR: The parameter 'AzureDevOpsProfileName' must be specified. To be safe: make this the same name as your repo. "
        }

        Write-Verbose "TRY: To check that VsTeam is installed. "
        $command = (Get-Command -Name "Add-VsTeamProfile" -ErrorAction SilentlyContinue) 
        if(-NOT $command) {
            throw "Error: You must call 'Install-Module VsTeam' to install the required module for Azure DevOps Access. "
        }
        Write-Verbose "DONE: VsTeam is installed. "

        Write-Verbose "TRY: To check that there is a profile specified. "
        $vsteamProfile = (Get-VSTeamProfile -Name $AzureDevOpsProfileName)
        if(-NOT $vsteamProfile) {
            throw "ERROR: You must configure a profile in VsTeam called '$($AzureDevOpsProfileName)'. This is a one-off operation. Enter: Add-VsTeamProfile -Account YOURVSTSACCOUNT -PersonalAccessToken YOURPAT -Name $($AzureDevOpsProfileName). Then call: Get-VsTeamProfile to view your profiles. "
        }
        Write-Verbose "DONE: The VsTeam Profile called $($AzureDevOpsProfileName) exists. "
    }
}

function Invoke-Bad {

    [CmdletBinding()]
    PARAM
    (
        [Parameter(Mandatory=$false)]
        [System.String]
        $AzureDevOpsProfileName = $env:AzureDevopsProfileName,

        [Parameter(Mandatory=$false)]
        [System.String]
        $AzureDevOpsBuildDefinitionName = $env:AzureDevOpsBuildDefinitionName,

        [Parameter(Mandatory=$false)]
        [System.String]
        $AzureDevOpsProjectName = $env:AzureDevOpsProjectName           
    )
    PROCESS {

        Write-Verbose "AzureDevopsProfileName: $($AzureDevopsProfileName)"
        Write-Verbose "AzureDevOpsBuildDefinitionName: $($AzureDevOpsBuildDefinitionName)"
        Write-Verbose "AzureDevOpsProjectName: $($AzureDevOpsProjectName)"

        if(-NOT $AzureDevopsProfileName) {
            throw "ERROR: The parameter 'AzureDevOpsProfileName' must be specified. To be safe: make this the same name as your repo. "
        }
        if(-NOT $AzureDevOpsBuildDefinitionName) {
            throw "ERROR: The parameter 'AzureDevOpsBuildDefinitionName' must be specified. This is the name of the build pipeline in Azure DevOps. "
        }        
        if(-NOT $AzureDevOpsProjectName) {
            throw "ERROR: The parameter 'AzureDevOpsProjectName' must be specified. This is the new of the Azure DevOps Project. "
        }          
        
        Write-Verbose "TRY: To set the VsTeamProfile to $($AzureDevOpsProfileName)"
        Set-VsTeamAccount -Profile $AzureDevOpsProfileName
        Write-Verbose "DONE: The VsTeamProfile has been set to $($AzureDevOpsProfileName)"

        #
        # Now queue the build...
        #
        $runningBuild = (Add-VSTeamBuild -BuildDefinitionName $AzureDevOpsBuildDefinitionName -ProjectName $AzureDevOpsProjectName)
        Write-Progress -Status $runningBuild.Status -PercentComplete -1 -Activity "Building $($AzureDevOpsBuildDefinitionName)..."

        #
        # Poll the build until it is complete
        #
        while($runningBuild.Status -ne "completed") 
        { 
            Start-Sleep 5;
            
            $runningBuild = (Get-VsTeamBuild -Id $runningBuild.Id -ProjectName $AzureDevOpsProjectName); 
            #Write-Output ($runningBuild | Select-Object -Property DefinitionName,BuildNumber,Id,Status,Result | Format-Table -HideTableHeaders)
            Write-Progress -Status $runningBuild.Status -PercentComplete -1 -Activity "Building $($AzureDevOpsBuildDefinitionName)..."
        }

        Write-Progress -Status $runningBuild.Result -PercentComplete -1 -Completed -Activity "Building $($AzureDevOpsBuildDefinitionName)..."

        if($runningBuild.Result -ne "succeeded") {
            throw "ERROR: The build $($runningBuild.Id) completed with result $($runningBuild.Result). 'succeeded' was expected. Not scheduling deploy. "
        }

        #
        # Now: schedule a deploy; and pass in a parameter
        #

    }

}

Test-BadAzureDevopsContext
