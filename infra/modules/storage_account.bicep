param location string
param storageModuleAccountName string
param skuName string = 'Standard_LRS'
param kind string = 'StorageV2'
param publicNetworkAccess string = 'Disabled'
param allowSharedKeyAccess bool = true

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageModuleAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowSharedKeyAccess: allowSharedKeyAccess
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: publicNetworkAccess
    encryption: {
      requireInfrastructureEncryption: true
    }
  }
}

output storageAccountId string = storageAccount.id
var connectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};QueueEndpoint=https://${storageAccount.name}.queue.core.windows.net/;FileEndpoint=https://${storageAccount.name}.file.core.windows.net/'
output connectionString string = connectionString
