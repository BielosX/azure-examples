#!/bin/bash

function deploy() {
    if [ "$1" == "" ]; then
        echo "Please provide resource group"
        exit 255
    fi
    az deployment group create \
    --name TerraformBackend \
    --resource-group "$1" \
    --template-file terraform_backend.bicep
}

function destroy() {
    if [ "$1" == "" ]; then
        echo "Please provide resource group"
        exit 255
    fi
    az deployment group delete \
    --name TerraformBackend \
    --resource-group "$1"
}

case "$1" in
    "deploy") deploy "$2" ;;
    "destroy") destroy "$2" ;;
esac