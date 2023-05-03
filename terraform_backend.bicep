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
    name: 'terraform-backend-sa'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: 'tfstate'
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}
