#This script invokes GitHub-CLI (Already installed on container image)
#To use this entrypoint script run: Docker run -e GH_TOKEN='myPatToken' -e GH_OWNER='orgName' -e GH_REPOSITORY='repoName' -d imageName
Param (
    [Parameter(Mandatory = $false)]
    [string]$owner = $env:GH_OWNER_ENV,
    [Parameter(Mandatory = $false)]
    [string]$repo = $env:GH_REPOSITORY,
    [Parameter(Mandatory = $false)]
    [string]$pat = $env:GH_TOKEN_ENV
)

$vsPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationpath
Write-Host "Microsoft Visual Studio path = '$vsPath'"
Import-Module (Get-ChildItem $vsPath -Recurse -File -Filter Microsoft.VisualStudio.DevShell.dll).FullName # Use module `Microsoft.VisualStudio.DevShell.dll`
Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments '-arch=x64'

#Use --with-token to pass in a PAT token on standard input. The minimum required scopes for the token are: "repo", "read:org".
#Alternatively, gh will use the authentication token found in environment variables. See gh help environment for more info.
#To use gh in GitHub Actions, add GH_TOKEN: $ to "env". on Docker run: Docker run -e GH_TOKEN='myPatToken'
$env:GH_TOKEN = $env:GH_TOKEN_ENV
gh auth login

git config --global user.email "github.very069@passmail.net"
git config --global user.name "Andrew Aye"

#Get Runner registration Token
$jsonObj = gh api --method POST -H "Accept: application/vnd.github.v3+json" "/orgs/$owner/actions/runners/registration-token"
$regToken = (ConvertFrom-Json -InputObject $jsonObj).token
$runnerBaseName = "dockerNode-"
$runnerName = $runnerBaseName + (((New-Guid).Guid).replace("-", "")).substring(0, 5)

try {
    #Register new runner instance
    write-host "Registering GitHub Self Hosted Runner on: $owner"
    ./config.cmd --unattended --url "https://github.com/$owner" --token $regToken --name $runnerName

    #Remove PAT token after registering new instance
    $pat=$null
    $env:GH_TOKEN=$null

    #Start runner listener for jobs
    ./run.cmd
}
catch {
    Write-Error $_.Exception.Message
}
finally {
    # Trap signal with finally - cleanup (When docker container is stopped remove runner registration from GitHub)
    # Does not currently work due to issue: https://github.com/moby/moby/issues/25982#
    # Perform manual cleanup of stale runners using Cleanup-Runners.ps1
    ./config.cmd remove --unattended --token $regToken
}
