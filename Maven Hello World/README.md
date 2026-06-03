## Description
Create a Github Actions pipeline which would do the following actions:
1. Increase the Patch part of the jar version (1.0.0 - > 1.0.1)
2. Compile the code
3. Package it into an artifact
4. Create an artifact item for the build
5. Create a docker image containing the artifact:
    - Tag the Docker image as the Jar version automatically.
    - The Docker image shouldn't run with root
6. Push the docker image that was created in the previous step to Docker Hub
7. Download and run the docker image.

Create a Helm chart and deploy the app

## Setup Instructions
1. Create Github `DOCKERHUB_USERNAME` variable and `DOCKERHUB_TOKEN` secret
2. Trigger the 'Build and Run' workflow