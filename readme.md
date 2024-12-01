# Run Instructions
## Windows
1. Save the enterprise name and access token into the environment (machine level)
> setx /M GH_ENTERPRISE <enterprise>
> setx /M GH_TOKEN <token>
2. CMD: docker-compose build
3. CMD: docker-compose up --scale runner=2 -d [runner=n is the number of containers to start]
4. CMD: docker-compose stop; docker rm $(docker ps -aq)
5. CMD: cleanup-runners.ps1

Troubleshooting
1. docker network ls
2. docker network prune

Remove Queued GitHub Actions
for id in $(gh run list --limit 5000 --jq ".[] | select (.status == \"queued\" ) | .databaseId" --json databaseId,status); do gh run cancel $id; done
