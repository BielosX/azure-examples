param location string = resourceGroup().location
param ip string

var uniqueStorageName = 'storage${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  kind: 'Storage'
  location: location
  name: uniqueStorageName
  sku: {
    name: 'Standard_GRS'
  }
  properties: {
    allowBlobPublicAccess: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: ip
        }
      ]
    }
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
    publicAccess: 'Blob'
  }
}

output storageAccountName string = storageAccount.name
