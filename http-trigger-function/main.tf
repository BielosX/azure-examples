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
  account_kind = "StorageV2"
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

resource "azurerm_log_analytics_workspace" "workspace" {
  name = "function-workspace"
  location = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
}

resource "azurerm_application_insights" "app-insights" {
  name = "app-insights"
  application_type = "web"
  location = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  workspace_id = azurerm_log_analytics_workspace.workspace.id
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

  site_config {
    application_insights_connection_string = azurerm_application_insights.app-insights.connection_string
    application_insights_key = azurerm_application_insights.app-insights.instrumentation_key
  }
}

resource "azurerm_monitor_diagnostic_setting" "function-logs" {
  name = "function-logs"
  target_resource_id = azurerm_windows_function_app.http-trigger-function-app.id
  log_analytics_destination_type = "Dedicated"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  enabled_log {
    category = "FunctionAppLogs"
    retention_policy {
      enabled = false
    }
  }
}