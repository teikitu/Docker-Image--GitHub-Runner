#!/bin/bash

GH_ENTERPRISE=$GH_ENTERPRISE
GH_TOKEN=$GH_TOKEN

cd /home/docker/actions-runner

REG_TOKEN=$(curl -sX POST -H "Accept: application/vnd.github+json" -H "Authorization: token ${GH_TOKEN}" https://api.github.com/enterprises/${GH_ENTERPRISE}/actions/runners/registration-token | jq .token --raw-output)
RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
RUNNER_NAME="Node-LNX-X64-${RUNNER_SUFFIX}"
./config.sh --unattended --url https://github.com/enterprises/$GH_ENTERPRISE --token ${REG_TOKEN} --runnergroup Teikitu-Standard --name ${RUNNER_NAME}

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

git config --global user.email "github.very069@passmail.net"
git config --global user.name "Andrew Aye"
gh auth login --with-token <<< $GH_TOKEN

echo Completed start script and running the runner.

./run.sh & wait $!
