param location string = resourceGroup().location

var uniqueStorageName = 'storage${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  kind: 'Storage'
  location: location
  name: uniqueStorageName
  sku: {
    name: 'Standard_GRS'
  }
  properties: {
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
  }
  tags: {
    purpose: 'TerraformBackend'
  }
}
