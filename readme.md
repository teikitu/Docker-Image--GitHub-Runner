# Run Instructions
## Windows
1. Create a docker_build.ps1 file to run the docker compose build with the required environment variables. The contents should be like:
> $env:GH_OWNER='***owner***'
> $env:GH_REPOSITORY='***repo***'
> $env:GH_TOKEN='***PAT***'
> docker-compose build
2. CMD: docker_build.ps1
3. CMD: docker-compose up --scale runner=1 -d [runner=n is the number of containers to start]
4. CMD: docker-compose stop; docker rm $(docker ps -aq)
5. CMD: cleanup-runners.ps1

Troubleshooting
1. docker network ls
2. docker network prune

Remove Queued GitHub Actions
for id in $(gh run list --limit 5000 --jq ".[] | select (.status == \"queued\" ) | .databaseId" --json databaseId,status); do gh run cancel $id; done
