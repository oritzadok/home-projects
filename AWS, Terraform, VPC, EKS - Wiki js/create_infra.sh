#!/bin/bash

set -euo pipefail

cd terraform

# The certificate will be referenced by the Kubernetes Ingress
echo "Generating a self-signed cert (OpenSSL)"
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout files/wiki.key \
  -out    files/wiki.crt \
  -subj   "/CN=wiki.internal.local"

terraform init
terraform apply --auto-approve

echo "Wiki.js page can be verified from inside the VPC by \"curl -k $(terraform output -raw app_url)\""
