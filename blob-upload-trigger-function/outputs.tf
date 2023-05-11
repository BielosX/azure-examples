output "function-app-name" {
  value = azurerm_windows_function_app.blob-upload-trigger-function-app.name
}

output "demo-storage-account-name" {
  value = azurerm_storage_account.demo-storage-account.name
}