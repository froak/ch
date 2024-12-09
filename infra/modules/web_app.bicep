param appUrl string
param appServicePlanName string
param env string
param location string
param keyVaultName string
param oaiName string
param outboundSubnetId string
param userManagedIdName string
param userManagedIdRGName string
param webAppName string
param applicationClientId string
// param allowedPrincipalsGroup string
param tenantId string = subscription().tenantId

var webSiteName = toLower('${webAppName}')
var environmentSetting = {
  DEV: {
    sku: 'S1'
    default_capacity: '1'
    maximum_capacity: '2'
    minimum_capacity: '1'
  }
  QA: {
    sku: 'P1v3'
    default_capacity: '1'
    maximum_capacity: '4'
    minimum_capacity: '1'
  }
  STG: {
    sku: 'S1'
    default_capacity: '1'
    maximum_capacity: '2'
    minimum_capacity: '1'
  }
  PRD: {
    sku: 'P1v3'
    default_capacity: '1'
    maximum_capacity: '4'
    minimum_capacity: '1'
  }
}

var args = [
  {
    direction: 'Increase'
    operator: 'GreaterThan'
    threshold: 70
  }
  {
    direction: 'Decrease'
    operator: 'LessThan'
    threshold: 30
  }
]

var rules = [for arg in args: {
  scaleAction: {
    cooldown: 'PT5M' // 5 minutes
    direction: arg.direction
    type: 'ChangeCount'
    value: '1'
  }
  metricTrigger: {
    metricName: 'CpuPercentage'
    metricResourceUri: appServicePlan.id
    operator: arg.operator
    statistic: 'Average'
    threshold: arg.threshold
    timeAggregation: 'Average'
    timeGrain: 'PT1M'
    timeWindow: 'PT10M'
  }
}]

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userManagedIdName
  scope: resourceGroup(userManagedIdRGName)
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: environmentSetting[env].sku
    capacity: 1
  }
  kind: 'linux'
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: webSiteName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}': {}
    }
  }
  properties: {
    clientCertEnabled: true
    clientCertMode: 'Required'
    clientCertExclusionPaths: '/'
    vnetRouteAllEnabled: true
    serverFarmId: appServicePlan.id
    keyVaultReferenceIdentity: userIdentity.id
    httpsOnly: true
    siteConfig: {
      http20Enabled: true
      linuxFxVersion: 'PYTHON|3.9'
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'false'
        }
        {
          name: 'OPEN_AI_ENDPOINT'
          value: 'https://${toLower(oaiName)}.openai.azure.com/'
        }
        {
          name: 'MANAGED_IDENTITY_CLIENT_ID'
          value: userIdentity.properties.clientId
        }
        {
          name: 'OPEN_AI_KEY'
          value: 'dummy'
        }
        {
          name: 'RUN_ENV'
          value: 'azure'
        }
        {
          name: 'OPENAI_HEALTH_CODE'
          value: '200'
        }
        {
          name: 'OPENAI_HEALTH_ERROR_MESSAGE'
          value: 'error has occured.'
        }
        {
          name: 'PYTHONUNBUFFERED'
          value: '1'
        }
      ]
    }
    // pipeline の globalip からアクセスさせるために、ここでは Enabled にする
    publicNetworkAccess: 'Enabled'
  }
}

resource authSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appService
  name: 'authsettingsV2'
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'RedirectToLoginPage'
      redirectToProvider: 'azureactivedirectory'
    }
    httpSettings: {
      forwardProxy: {
        convention: 'Custom'
        customHostHeaderName: 'X-Original-Host'
      }
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

resource ass 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: appServicePlan.name
  location: location
  properties: {
    enabled: true
    profiles: [
      {
        name: 'Scale out condition'
        capacity: {
          default: environmentSetting[env].default_capacity
          maximum: environmentSetting[env].maximum_capacity
          minimum: environmentSetting[env].minimum_capacity
        }
        rules: rules
      }
    ]
    targetResourceLocation: location
    targetResourceUri: appServicePlan.id
  }
}

resource vnetConnector 'Microsoft.Web/sites/networkConfig@2022-03-01' = {
  name: 'virtualNetwork'
  parent: appService
  properties: {
    subnetResourceId: outboundSubnetId
    swiftSupported: true
  }
}

output id string = appService.id
output name string = appService.name
