#!/bin/bash

set -euo pipefail

resource_group=$1
cluster=$2

echo "Getting kubeconfig file"
az aks get-credentials --resource-group $resource_group --name $cluster --file kubeconfig_temp --overwrite-existing

echo "Restarting deployment"
kubectl --kubeconfig=kubeconfig_temp rollout restart deploy keda-operator -n kube-system

echo "Waiting for pods to be ready"
kubectl --kubeconfig=kubeconfig_temp wait --for=condition=Ready pod -l app=keda-operator -n kube-system

rm -rf kubeconfig_temp