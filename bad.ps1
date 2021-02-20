#
# Module: bad.ps1 (Build and Deploy)
#
# Author: Greyhamwoohoo
#
# Purpose: Run a Yaml build pipeline (Azure DevOps)
#          Then run a Yaml release pipeline to consume the Build artifacts
#          (optionally deploy to an environment)
#

Set-StrictMode -Version 3.0

<#
# For debugging PowerShell without NPM: uncomment this block

$ErrorActionPreference="Stop"
# Set to Continue is you want -Verbose added to every call. Useful for troubleshooting. 
$VerbosePreference="Continue"

$env:AzureDevopsProfileName="azdev-cli-build-deploy-repo"
$env:AzureDevOpsBuildDefinitionName="azdev-cli-build"
$env:AzureDevOpsDeployDefinitionName="azdev-cli-deploy"
$env:AzureDevOpsProjectName="Public-Automation-Examples"
$env:AzureDevOpsEnvironment="azdev-cli-uat1"

# NOTE: This is only used for the Pipelines/Runs. When the API is promoted, this will likely need set to 6.1 or something. 
$env:AzureDevOpsApiverson="6.0-preview.1"
#> 

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

        Write-Verbose "TRY: To crudely establish the Git branch we are on. "
        $currentBranch = (git branch --show-current)
        if(-NOT $currentBranch) {
            throw "ERROR: The 'git' branch name could not be determined with 'git branch --show-current' (git 2.22+). The branch is required to schedule builds. "
        }
        Write-verbose "DONE: The current branch is $($currentBranch)"
    }
}

<#
.SYNOPSIS
Run the Build and Deploy pipelines

.PARAMETER AzureDevOpsProfileName
Name of the profile that has been configured by the VsTeam Module.

.PARAMETER AzureDevOpsBuildDefinitionName
Name of the Build Pipeline in Azure DevOps (YAML)

.PARAMETER AzureDevOpsDeployDefinitionName
Name of the Deploy Pipeline in Azure DevOps (YAML)

.PARAMETER AzureDevOpsProjectName
Project Name in Azure DevOps. The pipelines must reside in this Team Project. 

.PARAMETER AzureDevOpsApiVersion
API Version to use for starting the Deployment Pipeline. Use at least 6.0-preview.1 so that parameters (such as environments and resources) can be passed to the Deployment pipeline. 

.PARAMETER AzureDevOpsEnvironment
Optional environment to target. Can be null. If specified: will be passed as targetEnvironment (see deploy-env.yml for more information)

.PARAMETER SourceBranch
The branch name to build and deploy. 
#>
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
        $AzureDevOpsDeployDefinitionName = $env:AzureDevOpsDeployDefinitionName,        

        [Parameter(Mandatory=$false)]
        [System.String]
        $AzureDevOpsProjectName = $env:AzureDevOpsProjectName,

        [Parameter(Mandatory=$false)]
        [System.String]
        $AzureDevOpsApiVersion = $env:AzureDevOpsApiVersion,

        [Parameter(Mandatory=$false)]
        [System.String]
        $AzureDevOpsEnvironment = $env:AzureDevOpsEnvironment,

        [Parameter(Mandatory=$false)]
        [System.String]
        $SourceBranch = (git branch --show-current)
    )
    PROCESS {

        Write-Verbose "AzureDevopsProfileName: $($AzureDevopsProfileName)"
        Write-Verbose "AzureDevOpsBuildDefinitionName: $($AzureDevOpsBuildDefinitionName)"
        Write-Verbose "AzureDevOpsDeployDefinitionName: $($AzureDevOpsDeployDefinitionName)"
        Write-Verbose "AzureDevOpsProjectName: $($AzureDevOpsProjectName)"
        Write-Verbose "AzureDevOpsApiVerson: $($AzureDevOpsApiVersion)"
        Write-Verbose "AzureDevOpsEnvironment: $($AzureDevOpsEnvironment)"
        Write-Verbose "SourceBranch: $($SourceBranch)"

        if(-NOT $AzureDevopsProfileName) {
            throw "ERROR: The parameter 'AzureDevOpsProfileName' must be specified. To be safe: make this the same name as your repo. "
        }
        if(-NOT $AzureDevOpsBuildDefinitionName) {
            throw "ERROR: The parameter 'AzureDevOpsBuildDefinitionName' must be specified. This is the name of the Yaml build pipeline in Azure DevOps. "
        }        
        if(-NOT $AzureDevOpsDeployDefinitionName) {
            throw "ERROR: The parameter 'AzureDevOpsDeployDefinitionName' must be specified. This is the name of the Yaml deploy pipeline in Azure DevOps. "
        }    
        if(-NOT $AzureDevOpsApiVersion) {
            throw "ERROR: The parameter 'AzureDevOpsApiVersion' must be specified. This is the API Version required for the Runs API. "
        }                   
        if(-NOT $AzureDevOpsProjectName) {
            throw "ERROR: The parameter 'AzureDevOpsProjectName' must be specified. This is the name of the Azure DevOps Project. "
        }          
        
        Write-Verbose "TRY: To set the VsTeamProfile to $($AzureDevOpsProfileName)"
        Set-VsTeamAccount -Profile $AzureDevOpsProfileName
        Write-Verbose "DONE: The VsTeamProfile has been set to $($AzureDevOpsProfileName)"

        #
        # I cannot find a way of using Add-VsTeamBuild to queue a Yaml Pipeline that consumes build artifactgs (and accepts parameters)
        # So I need to use the pipelines/[BUILDDEFINITIONID]/runs API; find the BuildDefinitionId of the Deployment pipeline
        #
        $deployBuildDefinition = (Get-VSTeamBuildDefinition -ProjectName $AzureDevOpsProjectName ).Where{ $_.Name -eq $AzureDevOpsDeployDefinitionName }
        if(-NOT $deployBuildDefinition) {
            throw "ERROR: There is no Yaml Pipeline called '$($AzureDevOpsDeployDefinitionName)' in the Azure DevOps Project called '$($AzureDevOpsProjectName)'."
        }

        #
        # Queue the build...
        #
        $runningBuild = (Add-VSTeamBuild -BuildDefinitionName $AzureDevOpsBuildDefinitionName -ProjectName $AzureDevOpsProjectName -SourceBranch $SourceBranch)
        Write-Output "Build: $($runningBuild.InternalObject._links.web.href)"
        Write-Progress -Status $runningBuild.Status -PercentComplete -1 -Activity "Building $($AzureDevOpsBuildDefinitionName)..." -CurrentOperation "Build: $($runningBuild.InternalObject._links.web.href)"
        
        #
        # Poll the build until it is complete
        #
        while($runningBuild.Status -ne "completed") 
        { 
            Start-Sleep 5;
            
            $runningBuild = (Get-VsTeamBuild -Id $runningBuild.Id -ProjectName $AzureDevOpsProjectName); 
            Write-Progress -Status $runningBuild.Status -PercentComplete -1 -Activity "Building $($AzureDevOpsBuildDefinitionName)..." -CurrentOperation "Build: $($runningBuild.InternalObject._links.web.href)"
        }
        
        Write-Progress -Status $runningBuild.Result -PercentComplete -1 -Completed -Activity "Building $($AzureDevOpsBuildDefinitionName)..." -CurrentOperation "Build: $($runningBuild.InternalObject._links.web.href)"
        
        if($runningBuild.Result -ne "succeeded") {
            throw "ERROR: The build $($runningBuild.Id) completed with result $($runningBuild.Result). 'succeeded' was expected. Not scheduling deploy. "
        }
        
        #
        # Queue the deployment...
        # For this... we need to use the specific version (the buildName) of the build job. 
        # API Reference: https://docs.microsoft.com/en-us/rest/api/azure/devops/pipelines/runs/run%20pipeline?view=azure-devops-rest-6.0#runresourcesparameters
        #
        $bodyRaw = @{
            "stagesToSkip"=@();
            "resources"=@{ 
                "repositories"=@{
                    "self"=@{
                        "refName"="refs/heads/$($SourceBranch)"
                    } 
                };
                
                "pipelines"=@{
                    "$($AzureDevOpsBuildDefinitionName)"=@{
                        "version"="$($runningBuild.BuildNumber)"
                    }
                } 
            } 
        }

        if($AzureDevOpsEnvironment) {
            $bodyRaw["templateParameters"] = @{
                "targetEnvironment"="$($AzureDevOpsEnvironment)"
            }
        }

        # Default Depth is too small - so the likes of 'self' above will be serialized as the TypeName (HashTable). Force deep. 
        $bodyAsJson = ConvertTo-Json $bodyRaw -Depth 100

        Write-Verbose "Sending the following payload: "
        Write-Verbose $bodyAsJson

        # When we queue a Pipeline, we get the REST Response for a Pipeline Run. 
        # However: the response.id property can be used for querying the Build API
        $runningDeploy = Invoke-VSTeamRequest -Method POST -area "pipelines/$($deployBuildDefinition.Id)" -resource "runs"  -version "6.0-preview.1" -ProjectName $AzureDevOpsProjectName -UseProjectId -body $bodyAsJson
        Write-Verbose $runningDeploy

        $runningDeploy = (Get-VsTeamBuild -Id $runningDeploy.Id -ProjectName $AzureDevOpsProjectName); 
        Write-Output "Deploy: $($runningDeploy.InternalObject._links.web.href)"
        Write-Progress -Status $runningDeploy.Status -PercentComplete -1 -Activity "Deploying $($AzureDevOpsDeployDefinitionName)..." -CurrentOperation "Deploying: $($runningDeploy.InternalObject._links.web.href)"

        #
        # Poll the deploy until the deploy is complete
        #
        while($runningDeploy.Status -ne "completed") 
        { 
            Start-Sleep 5;
            
            $runningDeploy = (Get-VsTeamBuild -Id $runningDeploy.Id -ProjectName $AzureDevOpsProjectName); 
            Write-Progress -Status $runningDeploy.Status -PercentComplete -1 -Activity "Deploying $($AzureDevOpsDeployDefinitionName)..." -CurrentOperation "Deploy: $($runningDeploy.InternalObject._links.web.href)"
        }        

        Write-Progress -Status $runningDeploy.Result -PercentComplete -1 -Completed -Activity "Deploying $($AzureDevOpsDeployDefinitionName)..." -CurrentOperation "Deploy: $($runningDeploy.InternalObject._links.web.href)"
        
        if($runningDeploy.Result -ne "succeeded") {
            throw "ERROR: The deployment $($runningDeploy.Id) completed with result $($runningDeploy.Result). 'succeeded' was expected. "
        }        
    }
}
