param env string
param funcName string
param connectionString string
param modulePath string
param outboundSubnetId string
param location string
param lawName string
param lawResouceGroupName string
param userManagedIdName string
param userManagedIdRGName string
param applicationClientId string
param tenantId string = subscription().tenantId
param oaiNameChatBasic string
param oaiNameChatAdvance string
// param oaiNameChatWithFile string
// param oaiNameTranslate string
param oaiChatBasicModelName string
param oaiChatAdvanceModelName string

var runtime = 'python'
var functionAppName = funcName
var hostingPlanName = funcName
var applicationInsightsName = funcName
var functionWorkerRuntime = runtime

var environmentSetting = {
  DEV: {
    allowedAudiences: ['00000002-0000-0000-c000-000000000000', '8dae3f4b-1318-4d8b-929f-46db2ef8d6ad']
    minimumElasticInstanceCount: 1
  }
  QA: {
    allowedAudiences: ['00000002-0000-0000-c000-000000000000', '1898ebd0-36b5-49ab-81df-73162b5b23ed']
    minimumElasticInstanceCount: 2
  }
  STG: {
    allowedAudiences: ['8e2a7abd-0b5d-4bae-8e2c-ac5fbb2b4ddd']
    minimumElasticInstanceCount: 1
  }
  PRD: {
    allowedAudiences: ['d298a35d-4d60-40c4-a8f4-e1fed8a54b78']
    minimumElasticInstanceCount: 2
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    family: 'EP'
  }
  properties: {
    reserved: true
    maximumElasticWorkerCount: 20
  }
}

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userManagedIdName
  scope: resourceGroup(userManagedIdRGName)
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}': {}
    }
  }
  properties: {
    clientCertEnabled: true
    clientCertMode: 'Optional'
    serverFarmId: hostingPlan.id
    vnetRouteAllEnabled: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.9'
      http20Enabled: true
      functionsRuntimeScaleMonitoringEnabled: false
      minimumElasticInstanceCount: environmentSetting[env].minimumElasticInstanceCount
      healthCheckPath: '/health'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: connectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: connectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: modulePath
        }
        {
          name: 'AzureWebJobsFeatureFlags'
          value: 'EnableWorkerIndexing'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE_BLOB_MI_RESOURCE_ID'
          value: userIdentity.id
        }
        {
          name: 'OPEN_AI_ENDPOINT_FOR_CHATBASIC'
          value: 'https://${toLower(oaiNameChatBasic)}.openai.azure.com/'
        }
        {
          name: 'OPEN_AI_ENDPOINT_FOR_CHATADVANCE'
          value: 'https://${toLower(oaiNameChatAdvance)}.openai.azure.com/'
        }
        // {
        //   name: 'OPEN_AI_ENDPOINT_FOR_CHATWITHFILE'
        //   value: 'https://${toLower(oaiNameChatWithFile)}.openai.azure.com/'
        // }
        // {
        //   name: 'OPEN_AI_ENDPOINT_FOR_TRANSLATE'
        //   value: 'https://${toLower(oaiNameTranslate)}.openai.azure.com/'
        // }
        {
          name: 'MANAGED_IDENTITY_CLIENT_ID'
          value: userIdentity.properties.clientId
        }
        {
          name: 'OPEN_AI_ENGINE_FOR_CHATBASIC'
          value: oaiChatBasicModelName
        }
        {
          name: 'OPEN_AI_ENGINE_FOR_CHATADVANCE'
          value: oaiChatAdvanceModelName
        }
        // {
        //   name: 'OPEN_AI_ENGINE_FOR_CHATWITHFILE'
        //   value: 'gpt-35-turbo_0613'
        // }
        // {
        //   name: 'OPEN_AI_ENGINE_FOR_TRANSLATE'
        //   value: 'gpt-35-turbo_0613'
        // }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource authSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: functionApp
  name: 'authsettingsV2'
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'Return401'
      excludedPaths: [
        '/health'
        '/api/health'
      ]
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          openIdIssuer: 'https://login.microsoftonline.com/${tenantId}/v2.0'
          clientId: applicationClientId
          clientSecretSettingName: ''
        }
        validation: {
          defaultAuthorizationPolicy: {
            allowedPrincipals: {}
          }
          allowedAudiences: environmentSetting[env].allowedAudiences
        }
        isAutoProvisioned: false
      }
    }
    login: {
      tokenStore: {
        enabled: true
      }
    }
  }
}

// resource scmBasicPublishingCredentialsPolicies 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
//   name: 'scm'
//   kind: 'functionapp'
//   parent: functionApp
//   properties: {
//     allow: false
//   }
// }

// resource ftpBasicPublishingCredentialsPolicies 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
//   name: 'ftp'
//   kind: 'functionapp'
//   parent: functionApp
//   properties: {
//     allow: false
//   }
// }

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  scope: resourceGroup(lawResouceGroupName)
  name: lawName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    WorkspaceResourceId: law.id
  }
}

resource vnetConnector 'Microsoft.Web/sites/networkConfig@2022-03-01' = {
  name: 'virtualNetwork'
  parent: functionApp
  properties: {
    subnetResourceId: outboundSubnetId
    swiftSupported: true
  }
}

resource appPlanDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: hostingPlan
  name: 'appServicePlandiag'
  properties: {
    workspaceId: law.id
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

resource funcDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: functionApp
  name: 'functionDiag'
  properties: {
    workspaceId: law.id
    logs: [
      {
        category: 'FunctionAppLogs'
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

output id string = functionApp.id
