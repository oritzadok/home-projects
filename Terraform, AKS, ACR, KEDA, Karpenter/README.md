## Objective
Create a solution that receives a message from Service Bus, stores it in a
container in Blob Storage, and deploys it as a ScaledJob in AKS.

- Write a Python script that receives a message from a Service Bus Queue and
saves its content to a Storage Blob container with the current timestamp as the filename.
Filename Format: `YYYY-MM-DD-HH-MM-SS.txt`.
- Package the Python script into a Docker container. Push the Docker image to Azure Container Registry (ACR).
- Create a Storage Account with a Blob Container, an AKS cluster, and a Service
Bus queue using Terraform.
- Install Karpenter and create a node pool of Spot instances called “ng-spot”.
- Deploy a KEDA ScaledJob that will be executed on the dedicated node pool created by
Karpenter. The ScaledJob will use the Docker container, and KEDA will use
the Service Bus Queue Scaler to trigger it from 0.

## Setup
The purpose of this project is to create an Azure AKS-native, scalable solution, that receives messages from a Service Bus queue and stores them in a blob container.

It uses Terraform to perform the following:
- Creating the Azure infrasrtucture: container registry, service bus, storage account, and a Kubernetes cluster with Karpenter and KEDA enabled
- Building the Python code for message processing as a Docker image and pushing it to the registry
- Using Argo CD to deploy a Helm chart, containing the message processor as a ScaledJob, with a dedicated NodePool

### Prerequisites:

- Azure CLI installed and configured
- Terraform installed
- Docker installed
- kubectl installed

### Environment setup

1. Login to your Azure subscription (`az login`)
2. Provide the URL of this Git repository as a Terraform variable for `terraform/app/` module:
```
cat <<EOF > terraform/app/terraform.tfvars
git_repo = "https://..."
EOF
```
Other variables in `terraform/infra/variables.tf` and `terraform/app/variables.tf`, such as resource group location, are optional.

3.
```
export ARM_SUBSCRIPTION_ID=<your Azure subscription ID>
```
4. Run:
```
./scripts/create_env.sh
```
This will create the entire setup of the application using Terraform.

The environment details will be displayed at the end.

#### Testing:
In the Azure portal, go to the **Service Bus queue** and click on **Send messages**.
Provide some text and click **Send**.
Then go to the **Storage Account container** and verify that a file with the message content was created.


### Teardown

Run:
```
./scripts/delete_env.sh
```
This will delete the Terraform setup.