# azdev-cli-build-deploy
CLI Workflow to build and deploy branches to test environments from the cli. ie: npm run deploy:cli-uat1

## Usage
From Windows Terminal, and on the branch you are working, do something like this:

```bash
npm run bad:cli-uat1
```

That will run a build pipeline; wait for completion; and then deploy to the cli-uat1 environment. 

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

The profile 'azdev-cli-build-deploy-repo' will be set by all of the scripts (via Set-VsTeamAccount) to ensure the context is correct before running any scripts. 

## Design decisions
I have included *ALL* of the scripts in the packages.json here; it clearly makes more sense to externalize these (or even create a DSL for your company and publish it as an intenral PowerShell Module)


## Commands
A list of commands (some of which test the setup):

| Command                  | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
| npm run verify:context   | Runs some basic scripts to check all is good.                                  |


### Infrastructure
Two example pipelines are included:

1. build.yml (build definition: azdev-cli-build)
2. deploy.yml (build definition: azdev-cli-deploy)

In Azure DevOps, there are two Environments set up:

1. cli-uat1
2. cli-uat2
