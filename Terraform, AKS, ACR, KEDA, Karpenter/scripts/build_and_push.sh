#!/bin/bash

set -euo pipefail

acr_name=$1
acr_url=$2

image=${acr_url}/service-bus-consumer

pushd ../src/
echo "Building Docker image"
docker build -t $image .
popd

echo "Logging into Azure ACR"
az acr login --name $acr_name

echo "Pushing to ACR repository"
docker push $image

echo "Logging out of Azure ACR"
docker logout $acr_url

echo "Deleting from local"
docker rmi $image