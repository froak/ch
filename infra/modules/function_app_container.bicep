param location string

param functionName string
param storageConnectionString string

param integratedSubnetId string
param pepSubnetId string

param image string
param registryServerUrl string
param userManagedIdName string
param userManagedIdRGName string
param queueName string

param privateEndpointName string
param privateDnsZoneName string
param privateDnsZoneResouceGroupName string
param functionAppScaleLimit int = 5

param oaiName string

var functionAppName = functionName
var hostingPlanName = functionName
var applicationInsightsName = functionName

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userManagedIdName
  scope: resourceGroup(userManagedIdRGName)
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
  }
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
      linuxFxVersion: 'DOCKER|${image}'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: userIdentity.properties.clientId
      // functionAppScaleLimit: functionAppScaleLimit
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageConnectionString
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'AzureWebJobsMyQueue'
          value: storageConnectionString
        }
        {
          name: 'AzureWebJobsQueueStorage'
          value: storageConnectionString
        }
        {
          name: 'StorageAccountConnectionString'
          value: storageConnectionString
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: registryServerUrl
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'input_queue_name'
          value: queueName
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: functionName
        }
        {
          name: 'OPEN_AI_ENDPOINT'
          value: 'https://${toLower(oaiName)}.openai.azure.com/'
        }
        {
          name: 'MANAGED_IDENTITY_CLIENT_ID'
          value: userIdentity.properties.clientId
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource vnetConnector 'Microsoft.Web/sites/networkConfig@2022-03-01' = {
  name: 'virtualNetwork'
  parent: functionApp
  properties: {
    subnetResourceId: integratedSubnetId
    swiftSupported: true
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: pepSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
  scope: resourceGroup(privateDnsZoneResouceGroupName)
}

// https://blog.aimless.jp/archives/2022/07/use-integration-between-private-endpoint-and-private-dns-zone-in-bicep/
resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  parent: privateEndpoint
  name: 'dnsgroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output functionResourceId string = functionApp.id
