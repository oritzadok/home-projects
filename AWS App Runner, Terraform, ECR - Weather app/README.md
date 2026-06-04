## Overview
Build a simple weather API service using FastAPI that fetches weather
data from an external public API (like openweathermap or others). The service should be
designed to handle high traffic using asynchronous programming.

- Create a FastAPI application with a single endpoint `/weather`.
- The endpoint should accept a `GET` request with a `city` query parameter.
- Use Python's `asyncio` to asynchronously fetch the current weather data from the 
external API based on the `city` parameter.
- Implement proper error handling to manage potential API failures or invalid city names.
- Store each fetched weather response as a JSON file in an S3 bucket. 
The filename should be structured as `{city}_{timestamp}.json`.
- Use asynchronous methods to upload the data to the S3.
- After storing the json file, log the event (with city name, timestamp, and S3 URL/local
path) into a DynamoDB table. 
Ensure that database interactions are performed using async methods.
- Before fetching the weather data from the external API, check if the data for the
requested city (fetched within the last 5 minutes) already exists in S3.
  - If it exists, retrieve it directly without calling the external API.
  - Implement a mechanism to expire the cache after 5 minutes.
- Provide deployment scripts

## Setup
The application will be hosted on **AWS App Runner** service.

Alternative thoughts: Lambda & API Gateway, EKS, EC2 instance.

### Prerequisites:

- AWS CLI installed and configured
- Terraform installed
- Docker installed
- OpenWeather API key

### Deployment Instructions

1. Login to your AWS account programmatically, so Terraform will be able to create resources on your behalf.
2. Set your OpenWeather API key as an environment variable in the following form:
```
export TF_VAR_openweather_api_key=<API key>
```
3. Run:
```
./deploy.sh
```
This will create the entire setup of the application using Terraform.

The app endpoint (`https://<App Runner hostname>/weather/`) will be displayed at the end of deployment process.
You can test the app by running `curl "<app URL>?city=<city>"`.

An ECR repository will be available for pushing new image tags for the app.

### Teardown

Run:
```
./delete.sh
```
This will delete the Terraform setup.