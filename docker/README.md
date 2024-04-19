## Create .env file to set environment variable for docker container
bash gen-env-file.sh

## Build docker image and spin container
docker compose -f <dockerfile> up -d

## Run container
docker exec -it <container_name> bash
