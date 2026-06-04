#!/bin/bash

set -euo pipefail

ecr_repo=$1
gh_repo=$2

GH_HEADERS=(
  -H "Accept: application/vnd.github+json"
  -H "Authorization: Bearer ${GITHUB_TOKEN}"
  -H "X-GitHub-Api-Version: 2022-11-28"
)

if [ "$(aws ecr list-images --repository-name $ecr_repo --query 'length(imageIds)')" = "0" ]; then
  echo "ECR repository is empty. Triggering a build"
  curl -L -X POST "${GH_HEADERS[@]}" \
    "https://api.github.com/repos/${gh_repo}/actions/workflows/build.yaml/dispatches" \
    -d '{"ref":"main"}'
    
    sleep 5  # Give some time to enqueue the run
    
    echo "Getting run ID"
    read run_id run_url < <(curl -s "${GH_HEADERS[@]}" \
      "https://api.github.com/repos/${gh_repo}/actions/workflows/build.yaml/runs?branch=main&event=workflow_dispatch" \
      | jq -r '.workflow_runs | first | [.id, .html_url] | join(" ")')
      
    echo "Run URL: $run_url"
    echo "Run ID:  $run_id"
    
    echo "Waiting for the run to finish"
    while true; do
      conclusion=$(curl -s "${GH_HEADERS[@]}" \
        "https://api.github.com/repos/${gh_repo}/actions/runs/$run_id" \
         | jq -r '.conclusion')

      if [[ "$conclusion" != "null" ]]; then
        echo "Finished with status: ${conclusion}"
        break
      fi
    
      echo "Workflow is in the middle of running"
      sleep 30
    done
    
    if [[ "$conclusion" == "failure" ]]; then
      exit 1
    fi
fi