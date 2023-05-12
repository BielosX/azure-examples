terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key = "linux-vm.tfstate"
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
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
      graceful_shutdown = true
    }
  }
}

data "azurerm_resource_group" "resource-group" {
  name = var.resource-group
}

locals {
  resource-group-name = data.azurerm_resource_group.resource-group.name
  location = data.azurerm_resource_group.resource-group.location
}

resource "azurerm_network_security_group" "security-group" {
  name = "vm-security-group"
  location = local.location
  resource_group_name = local.resource-group-name

  security_rule {
    name = "allow-ssh"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "${var.source-ip}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "allow-outbound-https"
    priority = 101
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "allow-inbound-http"
    priority = 102
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "${var.source-ip}/32"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "demo-network" {
  name = "demo-network"
  address_space       = ["10.0.0.0/16"]
  location = local.location
  resource_group_name = local.resource-group-name

  subnet {
    name = "first"
    address_prefix = "10.0.1.0/24"
    security_group = azurerm_network_security_group.security-group.id
  }
}

resource "azurerm_public_ip" "public-ip" {
  name = "vm-public-ip"
  allocation_method = "Dynamic"
  location = local.location
  resource_group_name = local.resource-group-name
}

resource "azurerm_network_interface" "vm-interface" {
  name = "linux-vm-network-interface"
  location = local.location
  resource_group_name = local.resource-group-name

  ip_configuration {
    name = "primary"
    public_ip_address_id = azurerm_public_ip.public-ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id = tolist(azurerm_virtual_network.demo-network.subnet)[0].id
  }
}

resource "random_password" "admin-password" {
  length = 32
  min_lower = 2
  min_upper = 2
  min_numeric = 2
  min_special = 2
}

resource "azurerm_linux_virtual_machine" "demo-vm" {
  name = "demo-vm"
  location = local.location
  network_interface_ids = [azurerm_network_interface.vm-interface.id]
  resource_group_name = local.resource-group-name
  size = "Standard_B1s"
  disable_password_authentication = false
  admin_username = "adminuser"
  admin_password = random_password.admin-password.result
  custom_data = base64encode(file("${path.module}/init.sh"))

  os_disk {
    caching = "None"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer = "CentOS"
    publisher = "OpenLogic"
    sku = "8_5-gen2"
    version = "latest"
  }
}