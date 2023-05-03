terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key = "static-website.tfstate"
  }
}

data "azurerm_resource_group" "resource-group" {
  name = var.resource-group
}

resource "random_id" "storage-account-random" {
  byte_length = 17
}

resource "azurerm_storage_account" "storage-account" {
  account_replication_type = "GRS"
  account_tier = "Standard"
  location = data.azurerm_resource_group.resource-group.location
  name = "website${random_id.storage-account-random.dec}"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  account_kind = "StorageV2"
  public_network_access_enabled = false
  static_website {
    index_document = "index.html"
    error_404_document = "error.html"
  }
}