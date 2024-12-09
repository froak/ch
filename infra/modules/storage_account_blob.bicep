param storageModuleAccountName string
param containerNames array = [
  '$web'
  'modules'
  'builds'
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageModuleAccountName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      allowPermanentDelete: true
      enabled: true
      days: 90 // MDfC の指摘対応のために90日の指定が必要
    }
    containerDeleteRetentionPolicy: {
      allowPermanentDelete: true
      enabled: true
      days: 90 // MDfC の指摘対応のために90日の指定が必要
    }
  }
}

resource storageAccountResources 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [for container in containerNames: {
  name: '${storageAccount.name}/default/${container}'
  properties: {
    // publicAccess: 'None'
  }
}]
