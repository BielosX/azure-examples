#!/bin/bash

function check_resource_group() {
  if [ "$1" == "" ]; then
    echo "Please provide resource group"
    exit 255
  fi
}

function get_storage_account_name() {
  storage_account_name=$(az deployment group show \
    --name TerraformBackend \
    --resource-group "$1" \
    | jq -r '.properties.outputs.storageAccountName.value')
}

function deploy_backend() {
  check_resource_group "$1"
  ip=$(curl -s ifconfig.me/ip)
  echo "My IP: $ip"
  az deployment group create \
    --name TerraformBackend \
    --resource-group "$1" \
    --template-file terraform_backend.bicep \
    --parameters ip="$ip"
}

function destroy_backend() {
  check_resource_group "$1"
  az deployment group delete \
    --name TerraformBackend \
    --resource-group "$1"
}

function static_website() {
  check_resource_group "$1"
  get_storage_account_name "$1"
  pushd static-website || exit
  ip=$(curl -s ifconfig.me/ip)
  terraform init \
    -backend-config="resource_group_name=$1" \
    -backend-config="storage_account_name=$storage_account_name" || exit
  terraform apply -auto-approve -var "resource-group=$1" -var "allowed-ip=$ip"
  popd || exit
}

function static_website_destroy() {
  check_resource_group "$1"
  pushd static-website || exit
  ip=$(curl -s ifconfig.me/ip)
  terraform destroy -auto-approve -var "resource-group=$1" -var "allowed-ip=$ip"
  popd || exit
}

case "$1" in
  "deploy-backend") deploy_backend "$2" ;;
  "destroy-backend") destroy_backend "$2" ;;
  "static-website") static_website "$2" ;;
  "static-website-destroy") static_website_destroy "$2" ;;
esac