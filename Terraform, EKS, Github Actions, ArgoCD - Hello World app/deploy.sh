#!/bin/bash

set -euo pipefail

cd terraform

terraform init
terraform apply --auto-approve

echo "Getting EKS cluster kubeconfig"
aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw eks_cluster)

#echo "The web app is publicly accessible on $(terraform output -raw app_url)"
alb_hostname=`kubectl -n hello-app get ingress hello-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
echo "The web app will be publicly accessible soon on http://$alb_hostname"