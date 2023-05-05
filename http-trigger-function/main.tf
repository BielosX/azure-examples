terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key = "http-trigger-function.tfstate"
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.54.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "resource-group" {
  name = var.resource-group
}

resource "random_string" "storage-account-suffix" {
  length = 16
  special = false
  numeric = true
  upper = false
}

resource "azurerm_storage_account" "function-sa" {
  name = "function${random_string.storage-account-suffix.result}"
  resource_group_name= data.azurerm_resource_group.resource-group.name
  location = data.azurerm_resource_group.resource-group.location
  account_replication_type = "LRS"
  account_tier = "Standard"
}

resource "azurerm_service_plan" "service-plan" {
  name = "http-trigger-function-service-plan"
  location = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  os_type = "Windows"
  sku_name = "Y1"
}

resource "random_string" "function-suffix" {
  length = 16
  special = false
  numeric = true
  upper = false
}

resource "azurerm_windows_function_app" "http-trigger-function-app" {
  name = "function${random_string.function-suffix.result}"
  location = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  service_plan_id = azurerm_service_plan.service-plan.id
  storage_account_name = azurerm_storage_account.function-sa.name
  storage_account_access_key = azurerm_storage_account.function-sa.primary_access_key
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME: "dotnet"
    WEBSITE_RUN_FROM_PACKAGE: 1
  }

  site_config {}
}