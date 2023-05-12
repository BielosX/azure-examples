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

function backend() {
  check_resource_group "$1"
  ip=$(curl -s ifconfig.me/ip)
  echo "My IP: $ip"
  az deployment group create \
    --name TerraformBackend \
    --resource-group "$1" \
    --template-file terraform_backend.bicep \
    --parameters ip="$ip"
}

function backend_destroy() {
  check_resource_group "$1"
  az deployment group delete \
    --name TerraformBackend \
    --resource-group "$1"
}

function init_backend() {
  get_storage_account_name "$1"
  terraform init \
    -backend-config="resource_group_name=$1" \
    -backend-config="storage_account_name=$storage_account_name" || exit
}

function static_website() {
  check_resource_group "$1"
  pushd static-website || exit
  init_backend "$1"
  ip=$(curl -s ifconfig.me/ip)
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

function http_trigger_function() {
  check_resource_group "$1"
  pushd http-trigger-function || exit

  init_backend "$1"
  terraform apply -auto-approve -var "resource-group=$1"

  name=$(terraform show -json \
    | jq -r '.values.root_module.resources[] | select(.address == "azurerm_windows_function_app.http-trigger-function-app") | .values.name')

  pushd HttpTriggerFunction || exit
  rm -rf bin
  dotnet build || exit

  pushd bin/Debug/net6.0 || exit
  zip -r function.zip -- *
  az functionapp deployment source config-zip -g "$1" -n "$name" --src function.zip
  popd || exit

  popd || exit

  popd || exit
}

function http_trigger_function_destroy() {
  check_resource_group "$1"
  pushd http-trigger-function || exit
  terraform destroy -auto-approve -var "resource-group=$1"
  popd || exit
}

function blob_upload_trigger_function() {
  check_resource_group "$1"
  pushd blob-upload-trigger-function || exit

  pushd CalculateSHA256 || exit
  rm -rf bin
  dotnet build || exit
  pushd bin/Debug/net6.0 || exit
  zip -r function.zip -- *
  popd || exit
  popd || exit

  init_backend "$1"
  terraform apply -auto-approve -var "resource-group=$1"
  popd || exit
}

function blob_upload_trigger_function_destroy() {
  check_resource_group "$1"
  pushd blob-upload-trigger-function || exit
  terraform destroy -auto-approve -var "resource-group=$1"
  popd || exit
}

function linux_vm() {
  check_resource_group "$1"
  pushd linux-vm || exit
  init_backend "$1"
  ip=$(curl -s ifconfig.me/ip)
  terraform apply -auto-approve -var "resource-group=$1" -var "source-ip=$ip"
  popd || exit
}

function linux_vm_destroy() {
  check_resource_group "$1"
  pushd linux-vm || exit
  ip=$(curl -s ifconfig.me/ip)
  terraform destroy -auto-approve -var "resource-group=$1" -var "source-ip=$ip"
  popd || exit
}

function linux_vm_get_credentials() {
  pushd linux-vm || exit
  out=$(terraform output -json)
  user=$(jq -r '."admin-user".value' <<< "$out")
  password=$(jq -r '."admin-password".value' <<< "$out")
  echo "Username: $user, password: $password"
  popd || exit
}

case "$1" in
  "backend") backend "$2" ;;
  "backend-destroy") backend_destroy "$2" ;;
  "static-website") static_website "$2" ;;
  "static-website-destroy") static_website_destroy "$2" ;;
  "http-trigger-function") http_trigger_function "$2" ;;
  "http-trigger-function-destroy") http_trigger_function_destroy "$2" ;;
  "blob-upload-trigger-function") blob_upload_trigger_function "$2" ;;
  "blob-upload-trigger-function-destroy") blob_upload_trigger_function_destroy "$2" ;;
  "linux-vm" ) linux_vm "$2" ;;
  "linux-vm-destroy") linux_vm_destroy "$2" ;;
  "linux-vm-credentials") linux_vm_get_credentials ;;
esac