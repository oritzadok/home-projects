#!/bin/bash

set -euo pipefail

cd terraform/

pushd app/
echo "Destroying Argo CD applications"
terraform init
terraform destroy --auto-approve
popd

pushd helm/
echo "Destroying Helm charts"
terraform init
terraform destroy --auto-approve
popd

pushd infra/
echo "Destroying infrastructure"
terraform init
terraform destroy --auto-approve
popd