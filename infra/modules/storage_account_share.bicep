param storageAccountName string
param shareName string

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-05-01' = {
  name: '${storageAccountName}/default/${shareName}'

}
