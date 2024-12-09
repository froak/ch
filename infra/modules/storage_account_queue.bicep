param queueStorageAccountName string
param queueName string

resource queueStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: queueStorageAccountName
}

resource storageQueueService 'Microsoft.Storage/storageAccounts/queueServices@2022-05-01' = {
  name: 'default'
  parent: queueStorageAccount
}

resource internalQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-05-01' = {
  name: queueName
  parent: storageQueueService
}

output storageAccountId string = queueStorageAccount.id
var connectionString = 'DefaultEndpointsProtocol=https;AccountName=${queueStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(queueStorageAccount.id, queueStorageAccount.apiVersion).keys[0].value};QueueEndpoint=https://${queueStorageAccount.name}.queue.core.windows.net/;FileEndpoint=https://${queueStorageAccount.name}.file.core.windows.net/'
output connectoinString string = connectionString
