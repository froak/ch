param workspaceName string
param location string
@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param sku string = 'PerGB2018'

param retentionInDays int = 180
param resourcePermissions bool = true
param heartbeatTableRetention int = 180

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    features: {
      disableLocalAuth: false
      enableDataExport: false
      enableLogAccessUsingOnlyResourcePermissions: resourcePermissions
      // immediatePurgeDataOn30Days: bool
    }
    forceCmkForQuery: false
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Enabled'
    retentionInDays: retentionInDays
    sku: {
      name: sku
    }
  }
}

resource table 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: law
  name: 'Heartbeat'
  properties: {
    retentionInDays: heartbeatTableRetention
  }
}
