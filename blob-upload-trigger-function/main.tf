terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key = "blob-upload-trigger-function.tfstate"
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

locals {
  location = data.azurerm_resource_group.resource-group.location
  resource-group-name = data.azurerm_resource_group.resource-group.name
}

resource "random_string" "function-storage-account-suffix" {
  length = 14
  special = false
  numeric = true
  upper = false
}

resource "azurerm_storage_account" "function-storage-account" {
  name = "function${random_string.function-storage-account-suffix.result}"
  account_replication_type = "LRS"
  account_tier = "Standard"
  account_kind = "StorageV2"
  location = local.location
  resource_group_name = local.resource-group-name
}

resource "azurerm_service_plan" "function-service-plan" {
  name = "blob-upload-trigger-function-service-plan"
  location = local.location
  resource_group_name = local.resource-group-name
  os_type = "Windows"
  sku_name = "Y1"
}

resource "random_string" "function-suffix" {
  length = 16
  special = false
  numeric = true
  upper = false
}

resource "azurerm_windows_function_app" "blob-upload-trigger-function-app" {
  name = "function${random_string.function-suffix.result}"
  location = local.location
  resource_group_name = local.resource-group-name
  service_plan_id = azurerm_service_plan.function-service-plan.id
  storage_account_name = azurerm_storage_account.function-storage-account.name
  storage_account_access_key = azurerm_storage_account.function-storage-account.primary_access_key
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME : "dotnet"
    WEBSITE_RUN_FROM_PACKAGE : 1
    StorageConnectionString: azurerm_storage_account.demo-storage-account.primary_connection_string
  }
  zip_deploy_file = "${path.module}/CalculateSHA256/bin/Debug/net6.0/function.zip"

  site_config {
    application_insights_connection_string = azurerm_application_insights.app-insights.connection_string
    application_insights_key = azurerm_application_insights.app-insights.instrumentation_key
  }
}

resource "random_string" "demo-storage-account-suffix" {
  length = 20
  special = false
  numeric = true
  upper = false
}

resource "azurerm_storage_account" "demo-storage-account" {
  name = "demo${random_string.demo-storage-account-suffix.result}"
  account_replication_type = "LRS"
  account_tier = "Standard"
  account_kind = "StorageV2"
  location = local.location
  resource_group_name = local.resource-group-name
}

resource "azurerm_storage_container" "demo-container" {
  name = "demo-container"
  storage_account_name = azurerm_storage_account.demo-storage-account.name
}

resource "azurerm_log_analytics_workspace" "function-workspace" {
  name = "blob-upload-function-workspace"
  location = local.location
  resource_group_name = local.resource-group-name
}

resource "azurerm_application_insights" "app-insights" {
  name = "app-insights"
  application_type = "web"
  location = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  workspace_id = azurerm_log_analytics_workspace.function-workspace.id
}

resource "azurerm_monitor_diagnostic_setting" "function-logs" {
  name = "function-logs"
  target_resource_id = azurerm_windows_function_app.blob-upload-trigger-function-app.id
  log_analytics_destination_type = "Dedicated"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.function-workspace.id

  enabled_log {
    category = "FunctionAppLogs"
    retention_policy {
      enabled = false
    }
  }
}