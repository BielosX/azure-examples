output "admin-password" {
  value = azurerm_linux_virtual_machine.demo-vm.admin_password
  sensitive = true
}

output "admin-user" {
  value = azurerm_linux_virtual_machine.demo-vm.admin_username
}