param name string
param oaiLocation string
param userManagedIdName string
param userManagedIdRGName string
param customSubDomainName string = name
param kind string = 'OpenAI'
param publicNetworkAccess string
param sku object = {
  name: 'S0'
}
param lawName string
param lawResouceGroupName string

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userManagedIdName
  scope: resourceGroup(userManagedIdRGName)
}

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: oaiLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}': {}
    }
  }
  kind: kind
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: true
  }
  sku: sku
}

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  scope: resourceGroup(lawResouceGroupName)
  name: lawName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: account
  name: 'diag'
  properties: {
    workspaceId: law.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
    ]
  }
}

output endpoint string = account.properties.endpoint
output id string = account.id
output name string = account.name
