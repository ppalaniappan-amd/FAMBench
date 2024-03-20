## Create .env file to set environment variable for docker container
bash gen-env-file.sh

## Build docker image and spin container
docker compose up -d

## Run container
### For 8 GPU
docker exec -it ${USER}-fambench-cvt-tunableops-8GPU bash
### For 1 GPU
docker exec -it ${USER}-fambench-cvt-tunableops-1GPU bash
