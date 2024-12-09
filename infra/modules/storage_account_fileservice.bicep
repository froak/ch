param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageAccountName
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 90
      enabled: true
    }
  }
}
