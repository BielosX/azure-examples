terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key = "static-website.tfstate"
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

resource "random_id" "storage-account-random" {
  byte_length = 5
}

resource "azurerm_storage_account" "storage-account" {
  account_replication_type = "GRS"
  account_tier = "Standard"
  location = data.azurerm_resource_group.resource-group.location
  name = "website${random_id.storage-account-random.dec}"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  account_kind = "StorageV2"
  public_network_access_enabled = true
  network_rules {
    default_action = "Deny"
    ip_rules = [var.allowed-ip]
  }
  static_website {
    index_document = "index.html"
    error_404_document = "error.html"
  }
}

resource "azurerm_storage_blob" "index" {
  name = "index.html"
  storage_account_name = azurerm_storage_account.storage-account.name
  storage_container_name = "$web"
  type = "Block"
  content_type = "text/html"
  source_content = <<-EOT
  <html>
    <body>
      <h1>Hello from Storage Account</h1>
    </body>
  </html>
  EOT
}

resource "azurerm_storage_blob" "error" {
  name = "error.html"
  storage_account_name = azurerm_storage_account.storage-account.name
  storage_container_name = "$web"
  type = "Block"
  content_type = "text/html"
  source_content = <<-EOT
  <html>
    <body>
      <h1>Something went wrong</h1>
    </body>
  </html>
  EOT
}