# azdev-cli-build-deploy
CLI Workflow to build and deploy branches to test environments from the cli. ie: npm run bad

Only tested with YAML build and release pipelines. 

## Usage
From Windows Terminal, and on the branch you are working, do something like this:

```bash
npm run bad
```

That will run a build pipeline; wait for completion; and then run the deploy pipeline; wait for completion. 

### Why?
We often need adhoc deployments of our current branch to different environments; almost 'fire and forget'. 

## Setup
This is intended to run on top of PowerShell (or Posh Core) and uses the VsTeam PowerShell Module. 

To set up a Least Privelege PAT:

![Least Privelege PAT](docs/pat-permissions.png "Least Privelege PAT")

To set up the PowerShell session before running any commands:

```
Install-Module vsteam
Add-VsTeamProfile -Account YOURVSTSACCOUNT -PersonalAccessToken YOURPAT -Name azdev-cli-build-deploy-repo
```

The profile 'azdev-cli-build-deploy-repo' will be set by all of the npm commands (via Set-VsTeamAccount) to ensure the context is correct before running any PowerShell code. 

## Design decisions
The PowerShell logic is in the bad.ps1 file. 

I have wrapped up the calls with npm to test its viability; my feeling is it makes sense to turn bad.ps1 into a DSL for your use case and invoke it directly. 

## Commands
A list of commands (some of which test the setup):

| Command                       | Description                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------ |
| npm run test-bad              | Verifies everything is configured            |
| npm run bad                   | Build a YAML Pipeline; then Deploy using its resources |


### Infrastructure
Two example pipelines are included - the npm commands directly refer to them to queue new builds and wait for completion:

| Build File | Azure DevOps Build Definition | Description                                                                |
| ---------- | ----------------------------- | -------------------------------------------------------------------------- |
| build.yml  | azdev-cli-build               | A simple build; the scripts wait for completion before scheduling the next | 
| deploy.yml | azdev-cli-deploy              | A simple deploy (parameterized to deploy to the chosen environment using resources from azdev-cli-build |

# TODO: 
In Azure DevOps, there are two Environments set up:

1. cli-uat1
2. cli-uat2
