#!/bin/bash

function check_resource_group() {
  if [ "$1" == "" ]; then
    echo "Please provide resource group"
    exit 255
  fi
}

function get_storage_account_name() {
  id=$(az deployment group show \
    --name TerraformBackend \
    --resource-group "$1" \
    | jq -r '.properties.outputResources | map(.id) | .[] | select(test("storageAccounts/[a-z0-9]+$"))')
  IFS='/' read -r -a elements <<< "$id"
  length=${#elements[@]}
  last=$((length-1))
  storage_account_name=${elements[last]}
}

function deploy() {
  check_resource_group "$1"
  az deployment group create \
    --name TerraformBackend \
    --resource-group "$1" \
    --template-file terraform_backend.bicep
}

function destroy() {
  check_resource_group "$1"
  az deployment group delete \
    --name TerraformBackend \
    --resource-group "$1"
}

function static_website() {
  check_resource_group "$1"
  get_storage_account_name "$1"
  pushd static-website || exit
  terraform init \
    -backend-config="resource_group_name=$1" \
    -backend-config="storage_account_name=$storage_account_name" || exit
  terraform apply -auto-approve -var "resource-group=$1"
  popd || exit
}

case "$1" in
  "deploy") deploy "$2" ;;
  "destroy") destroy "$2" ;;
  "static-website") static_website "$2" ;;
esac