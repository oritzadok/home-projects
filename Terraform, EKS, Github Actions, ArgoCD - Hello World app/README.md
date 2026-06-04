## Description
Build a small Python web application, containerize it, and deploy it to Kubernetes.

- Create a simple “Hello World” style Python web application that runs on Linux.
- Containerize the application in a reproducible and portable way.
  - run container as non-root
  - minimal base image
- Deploy the containerized application to a Kubernetes cluster.
- Expose the application so it can be accessed and tested.
- Basic observability
- A minimal CI pipeline

## Setup Instructions
### Prerequisites:

- An existing VPC and subnets that meet Amazon EKS requirements (this code is not responsible of creating these resources at this time)
- AWS CLI installed and configured
- Terraform installed
- Helm installed (can try without this)
- Github Personal Access Token with permissions to create repository secrets/variables and trigger workflow runs.
  Will be used by Terraform to:
    * Create repository secrets & variables in the Github repository
    * Trigger the build & push workflow one time, to build an initial container image (in case the ECR repository is empty), pre-deployment.
- jq installed
- kubectl installed

### Deployment Instructions

1. Login to your AWS account programmatically, so Terraform will be able to create resources on your behalf.
2. Set your Github PAT token:
```
export GITHUB_TOKEN=<Github Personal Access Token>
```
3. Create a `terraform.tfvars` file in the `terraform` directory, and specify the below Terraform parameters:
- `aws_region` - the AWS region where you want the infrastructure to be deployed
- `env_name`   - a prefix to identify the environment resources (can be your own name)
- `subnet_ids` - a list of subnets where you want your EKS cluster & worker nodes to be created in
- `gh_repo`    - the name of this Github reopsitory in the form of `<org>/<repo>`

```
cat <<EOF > terraform/terraform.tfvars
aws_region = "<aws_region>"
env_name   = "<can_be_your_own_name>"
subnet_ids = ["<subnet1-id>", "<subnet2-id>", "<subnet3-id>", ...]
gh_repo    = "<this_repo_org>/<this_repo_name>"
EOF
```
4. Run:
```
./deploy.sh
```
This will create the entire setup of the application using Terraform. It'll:
* Provision an AWS EKS cluster & worker node group
* Create an AWS ECR repository used for storing container images
* Set up this Github repository with the relevant secrets & variables required for the CI/CD workflow
* Trigger the CI/CD workflow to build an initial container image
* Create an Argo CD application to deploy the application Helm chart on the cluster

The app URL (`http://<ALB DNS name>`) will be displayed at the end of deployment process.
You can test the app by running `curl <app URL>`

#### CI/CD process
There is a Github Actions workflow, triggered at every change to the source code.
It first builds a container image and pushes it to the ECR repository, then modifies the `helm_values.yaml` file with the new container image and commiting the changes.
The `helm_values.yaml` is used to store the real-time values for the app, and is monitored by Argo CD.
As soon as the file changes, Argo CD should apply the changes.

#### Additional notes
* The application pods have `/ready` & `/healthz` HTTP endpoints + readiness/liveness probes.
* The Amazon CloudWatch Observability add-on is installed on the cluster for cluster logs and metrics.
It enables Container Insights and Application Signals for cluster health and performance observability.
* The application containers run with a non-root user.

#### Build and run locally
```
cd app
docker build -t hello:v1 .
docker run -d -p 5000:5000 hello:v1
sleep 5
curl 127.0.0.1:5000
```

### Teardown

Run:
```
./delete.sh
```
This will delete the Terraform setup.