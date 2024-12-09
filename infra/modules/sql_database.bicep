param sqlServerName string
param sqlDatabaseName string
param location string
param administratorLogin string
@secure()
param administratorLoginPassword string
param administoratorsSid string
param administratorsLogin string
param subnetId string
param privateEndpointName string
param privateDnsZoneResouceGroupName string
param privateDnsZoneName string
param storageAccountAccessKey string
param storageAccountSubscriptionId string
param storageEndpoint string

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: false
      principalType: 'User'
      login: administratorsLogin
      sid: administoratorsSid
      tenantId: subscription().tenantId
    }
    // federatedClientId: 'string'
    // keyId: 'string'
    minimalTlsVersion: '1.2'
    // primaryUserAssignedIdentityId: 'string'
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: 'Disabled'
    // version: 'string'
  }
}

resource auditingSettings 'Microsoft.Sql/servers/auditingSettings@2022-05-01-preview' = {
  name: 'default'
  parent: sqlServer
  properties: {
    auditActionsAndGroups: [
      'BATCH_COMPLETED_GROUP'
      'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
    ]
    isAzureMonitorTargetEnabled: false
    isDevopsAuditEnabled: false
    isManagedIdentityInUse: false
    isStorageSecondaryKeyInUse: false
    queueDelayMs: null
    retentionDays: 5
    state: 'Enabled'
    storageAccountAccessKey: storageAccountAccessKey
    storageAccountSubscriptionId: storageAccountSubscriptionId
    storageEndpoint: storageEndpoint
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maintenanceConfigurationId: subscriptionResourceId('Microsoft.Maintenance/publicMaintenanceConfigurations', 'SQL_JapanEast_DB_2')
    requestedBackupStorageRedundancy: 'Local'
    // sampleName: 'AdventureWorksLT'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
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
