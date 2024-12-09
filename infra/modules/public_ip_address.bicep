param name string
param location string
// param logAnalyticsWorkspaceNameResourceGroupName string
// param workspaceName string

// param alertRuleName string
// param actionGroupResouceGroupName string
// param actionGroupName string

// resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
//   scope: resourceGroup(logAnalyticsWorkspaceNameResourceGroupName)
//   name: workspaceName
// }

resource gatewayIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: name
  location: location
  properties: {
    ddosSettings: {
      protectionMode: 'Enabled'
    }
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

// resource publicIpDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   scope: gatewayIP
//   name: 'diag-${name}'
//   properties: {
//     workspaceId: law.id
//     logs: [
//       {
//         categoryGroup: 'audit'
//         enabled: true
//       }
//     ]
//   }
// }

// MDfC の指摘への対応として、DDoS の Alert を作成したが、
// Alert を作成しても、MDfC の指摘が消えないため、Global へのエスカレーションとして作成しないこととしたため
// ひとまずコメントアウト

// resource actionGroup 'Microsoft.Insights/actionGroups@2021-09-01' existing = {
//   scope: resourceGroup(actionGroupResouceGroupName)
//   name: actionGroupName
// }

// resource metricAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = {
//   name: alertRuleName
//   location: 'global'
//   properties: {
//     actions: [
//       {
//         actionGroupId: actionGroup.id
//         webHookProperties: {}
//       }
//     ]
//     autoMitigate: true
//     criteria: {
//       allOf: [
//         {
//           threshold: 1
//           name: 'Metric1'
//           metricNamespace: 'Microsoft.Network/publicIPAddresses'
//           metricName: 'IfUnderDDoSAttack'
//           operator: 'GreaterThanOrEqual'
//           timeAggregation: 'Maximum'
//           skipMetricValidation: false
//           criterionType: 'StaticThresholdCriterion'
//         }
//       ]
//       'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
//     }
//     enabled: true
//     evaluationFrequency: 'PT1M'
//     scopes: [
//       gatewayIP.id
//     ]
//     severity: 2
//     targetResourceRegion: location
//     targetResourceType: 'Microsoft.Network/publicIPAddresses'
//     windowSize: 'PT5M'
//   }
// }

output gatewayIPID string = gatewayIP.id
