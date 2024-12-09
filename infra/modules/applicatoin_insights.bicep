param applicationInsightsName string
param location string
param workspaceName string
param logAnalyticsWorkspaceNameResourceGroupName string
param kind string
param applicatoinType string
param requestSource string

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  scope: resourceGroup(logAnalyticsWorkspaceNameResourceGroupName)
  name: workspaceName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: kind
  properties: {
    Application_Type: applicatoinType
    Request_Source: requestSource
    WorkspaceResourceId: law.id
  }
}

output instrumentationKey string = applicationInsights.properties.InstrumentationKey
