#!/bin/bash

function deploy() {
    az deployment group create \
    --name TerraformBackend \
    --resource-group "$1" \
    --template-file terraform_backend.bicep
}

case "$1" in
    "deploy") deploy "$2" ;;
esac