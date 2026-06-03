#!/bin/bash

set -euo pipefail

cd terraform

terraform init

echo "Getting EKS cluster kubeconfig"
aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw eks_cluster)

helm uninstall $(terraform output -raw wiki_helm_release) -n $(terraform output -raw namespace)
# Persistant Volume Claims for the database are not deleted automatically. They need to be manually deleted
echo "Deleting remaining PVCs"
kubectl delete pvc --all -n $(terraform output -raw namespace)
# Cleaner approach: use kubectl to get the list of EC2 volumes associated with all PVCs in the namespace
aws ec2 describe-volumes \
  --filters \
    "Name=tag:kubernetes.io/created-for/pvc/namespace,Values=$(terraform output -raw namespace)" \
    "Name=tag:KubernetesCluster,Values=$(terraform output -raw eks_cluster)" \
    "Name=tag:ebs.csi.aws.com/cluster,Values=true" \
  --query "Volumes[].VolumeId" \
  --output text | xargs -r -n1 aws ec2 delete-volume --volume-id

terraform destroy --auto-approve
