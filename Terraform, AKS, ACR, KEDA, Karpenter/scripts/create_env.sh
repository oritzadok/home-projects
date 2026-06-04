#!/bin/bash

set -euo pipefail

cd terraform/

pushd infra/

echo "Creating infrastructure"
terraform init
terraform apply --auto-approve

resource_group=$(terraform output -raw resource_group)
aks_cluster=$(terraform output -raw kubernetes_cluster)
acr_name=$(terraform output -raw acr_name)
acr_url=$(terraform output -raw acr_url)
service_bus_namespace=$(terraform output -raw service_bus_namespace)
service_bus_queue=$(terraform output -raw service_bus_queue)
storage_account=$(terraform output -raw storage_account)
storage_account_container=$(terraform output -raw storage_account_container)
consumer_managed_identity=$(terraform output -raw consumer_managed_identity)
keda_managed_identity=$(terraform output -raw keda_managed_identity)

popd

echo "Getting Kubernetes cluster kubeconfig"
az aks get-credentials --resource-group $resource_group --name $aks_cluster --file ./kubeconfig --overwrite-existing

pushd helm/

echo "Deploying necessary Helm charts on Kubernetes cluster"
terraform init
terraform apply --auto-approve

popd

pushd ../scripts/
echo "Building container image tag"
./build_and_push.sh $acr_name $acr_url
popd

acr_repo="${acr_url}/service-bus-consumer"

pushd app/

# Helm Parameters are specified as Terraform variables for simplicity.
# In real world - use values file
echo "Preparing Helm values override file for workload deployment"
cat <<EOF >> terraform.tfvars
acr_repo = "${acr_repo}"
consumer_managed_identity = "${consumer_managed_identity}"
keda_managed_identity = "${keda_managed_identity}"
service_bus_namespace = "${service_bus_namespace}"
storage_account = "${storage_account}"
EOF

echo "Deploying Argo CD applications"
terraform init
terraform apply --auto-approve

popd

cat <<EOF
Resource group:        $resource_group
Kubernetes cluster:    $aks_cluster
ACR repository:        $acr_repo
Service Bus namespace: $service_bus_namespace
Queue name:            $service_bus_queue
Storage account:       $storage_account
Container name:        $storage_account_container
EOF
