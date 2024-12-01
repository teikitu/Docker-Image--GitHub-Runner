#This script invokes GitHub-CLI (Pre-installed on container image)
Param (
    [Parameter(Mandatory = $false)]
    [string]$GH_ENTERPRISE = $env:GH_ENTERPRISE,
    [Parameter(Mandatory = $false)]
    [string]$GH_TOKEN = $env:GH_TOKEN
)

#Use --with-token to pass in a PAT token on standard input. The minimum required scopes for the token are: "repo", "read:org".
#Alternatively, gh will use the authentication token found in environment variables. See gh help environment for more info.
#To use gh in GitHub Actions, add GH_TOKEN: $ to "env". on Docker run: Docker run -e GH_TOKEN='myPatToken'
gh auth login --with-token $GH_TOKEN

#Cleanup#
#Look for any old/stale dockerNode- registrations to clean up
#Windows containers cannot gracefully remove registration via powershell due to issue: https://github.com/moby/moby/issues/25982#
#For this reason we can use this script to cleanup old offline instances/registrations
$runnerBaseName = "Node-"
$runnerListJson = gh api -H "Accept: application/vnd.github.v3+json" "/enterprises/$GH_ENTERPRISE/actions/runners"
$runnerList = (ConvertFrom-Json -InputObject $runnerListJson).runners

Foreach ($runner in $runnerList) {
    try {
        If (($runner.name -like "$runnerBaseName*") -and ($runner.status -eq "offline")) {
            write-host "Unregsitering old stale runner: $($runner.name)"
            gh api --method DELETE -H "Accept: application/vnd.github.v3+json" "/enterprises/$GH_ENTERPRISE/actions/runners/$($runner.id)"
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

#Remove PAT token after cleanup
$GH_TOKEN=$null
