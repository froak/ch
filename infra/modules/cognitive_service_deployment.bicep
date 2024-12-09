param name string
param kind string = 'OpenAI'
param chatGptDeploymentName string
param chatGptModelName string
param capacity int = 5
param version string

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: name
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: account
  name: chatGptDeploymentName
  sku: {
    name: 'Standard'
    capacity: capacity
  }
  properties: {
    model: {
      format: kind
      name: chatGptModelName
      version: version
    }
  }
}


output endpoint string = account.properties.endpoint
output id string = account.id
output name string = account.name
