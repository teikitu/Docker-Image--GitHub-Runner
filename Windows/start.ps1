#This script invokes GitHub-CLI (Already installed on container image)
Param (
    [Parameter(Mandatory = $false)]
    [string]$GH_ENTERPRISE = $env:GH_ENTERPRISE,
    [Parameter(Mandatory = $false)]
    [string]$GH_TOKEN = $env:GH_TOKEN
)

$vsPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationpath
Write-Host "Microsoft Visual Studio path = '$vsPath'"
Import-Module (Get-ChildItem $vsPath -Recurse -File -Filter Microsoft.VisualStudio.DevShell.dll).FullName # Use module `Microsoft.VisualStudio.DevShell.dll`
Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments '-arch=x64'

git config --global user.email "github.very069@passmail.net"
git config --global user.name "Andrew Aye"
gh auth login

#Get Runner registration Token
$jsonObj = gh api --method POST -H "Accept: application/vnd.github.v3+json" "/enterprises/$GH_ENTERPRISE/actions/runners/registration-token"
$regToken = (ConvertFrom-Json -InputObject $jsonObj).token
$runnerBaseName = "Node-WIN-X64-"
$runnerName = $runnerBaseName + (((New-Guid).Guid).replace("-", "")).substring(0, 5)

try {
    #Register new runner instance
    write-host "Registering GitHub Self Hosted Runner on: $GH_ENTERPRISE"
    ./config.cmd --unattended --url "https://github.com/enterprises/$GH_ENTERPRISE" --token $regToken --name $runnerName --runnergroup Teikitu-Standard --work _work

    #Remove PAT token after registering new instance
    $GH_TOKEN=$null

    Write-Host Completed start script and running the runner.

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
