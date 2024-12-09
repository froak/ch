param agwName string
param agwSubnetId string
param env string
param userManagedIdName string
param userManagedIdRGName string
param location string
param keyContainerName string
param keyvaultName string
param domain string
param apiBackendFqdn string
param uiBackendFqdn string
param agwPrivateIp string

param pipName string

param lawName string
param lawResouceGroupName string

// 共通
var agwId = resourceId('Microsoft.Network/applicationGateways', agwName)
var gatewayIPConfigurationName = '${agwName}GIPConf'
var frontendIPConfigurationName = '${agwName}FIPConf'
var frontendPrivateIPConfigurationName = '${agwName}FPrivateIPConf'
var frontendPrivateIPConfigurationID = '${agwId}/frontendIPConfigurations/${frontendPrivateIPConfigurationName}'
var frontendIPPortName = '${agwName}FIPPort'
var frontendIPPortID = '${agwId}/frontendPorts/${frontendIPPortName}'
var keyVaultSecretId = 'https://${keyContainerName}.vault.azure.net/secrets/${keyvaultName}'
var sslCertificateName = '${agwName}sslCertificate'
var sslCertificateId = '${agwId}/sslCertificates/${sslCertificateName}'

var httpsListenerName = '${agwName}HttpsListener'
var apiBackendPoolName = '${agwName}ApiBackendPool'
var uiBackendPoolName = '${agwName}UiBackendPool'
var httpsBackendSettingName = '${agwName}HttpsBuckendSetting'
var probeName = '${agwName}Probe'
var routingRuleName = '${agwName}RoutingRule'
var urlPathMapName = '${agwName}UrlPathMap'

var httpsListenerId = '${agwId}/httpListeners/${httpsListenerName}'
var apiBackendPoolId = '${agwId}/backendAddressPools/${apiBackendPoolName}'
var uiBackendPoolId = '${agwId}/backendAddressPools/${uiBackendPoolName}'
var httpsBackendSettingId = '${agwId}/backendHttpSettingsCollection/${httpsBackendSettingName}'
var probeId = '${agwId}/probes/${probeName}'
var urlPathMapId = '${agwId}/urlPathMaps/${urlPathMapName}'

var environmentSetting = {
  DEV: {
    skuName: 'WAF_V2'
    skuTier: 'WAF_v2'
    default_capacity: 2
    maxCapacity: 3
    minCapacity: 1
  }
  QA: {
    skuName: 'WAF_V2'
    skuTier: 'WAF_v2'
    default_capacity: 2
    maxCapacity: 3
    minCapacity: 1
  }
  STG: {
    skuName: 'WAF_V2'
    skuTier: 'WAF_v2'
    default_capacity: 2
    maxCapacity: 3
    minCapacity: 1
  }
  PRD: {
    skuName: 'WAF_V2'
    skuTier: 'WAF_v2'
    default_capacity: 2
    maxCapacity: 3
    minCapacity: 1
  }
}

module deploymentGatewayIP 'public_ip_address.bicep' = {
  name: pipName
  params: {
    name: pipName
    location: location
    // logAnalyticsWorkspaceNameResourceGroupName: lawResouceGroupName
    // workspaceName: lawName
    // actionGroupName: actionGroupName
    // actionGroupResouceGroupName: actionGroupResouceGroupName
    // alertRuleName: alertRuleName
  }
}

resource agwUserIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userManagedIdName
  scope: resourceGroup(userManagedIdRGName)
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2022-07-01' = {
  name: agwName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${agwUserIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: environmentSetting[env].skuName
      tier: environmentSetting[env].skuTier
    }
    autoscaleConfiguration: {
      maxCapacity: environmentSetting[env].maxCapacity
      minCapacity: environmentSetting[env].minCapacity
    }
    sslCertificates: [
      {
        id: sslCertificateId
        name: sslCertificateName
        properties: {
          keyVaultSecretId: keyVaultSecretId
        }
      }
    ]
    sslPolicy: {
      // minProtocolVersion: 'TLSv1_2'
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20220101S' // https://learn.microsoft.com/ja-jp/azure/application-gateway/application-gateway-ssl-policy-overview#predefined-tls-policy
    }
    gatewayIPConfigurations: [
      {
        name: gatewayIPConfigurationName
        properties: {
          subnet: {
            id: agwSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIPConfigurationName
        properties: {
          publicIPAddress: {
            id: deploymentGatewayIP.outputs.gatewayIPID
          }
        }
      }
      {
        name: frontendPrivateIPConfigurationName
        properties: {
          privateIPAddress: agwPrivateIp
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: agwSubnetId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendIPPortName
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: uiBackendPoolName
        properties: {
          backendAddresses: [
            {
              ipAddress: uiBackendFqdn
            }
          ]
        }
      }
      {
        name: apiBackendPoolName
        properties: {
          backendAddresses: [
            {
              ipAddress: apiBackendFqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: httpsBackendSettingName
        properties: {
          requestTimeout: 240
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          path: '/'
          pickHostNameFromBackendAddress: true
          probe: {
            id: probeId
          }
        }
      }
    ]
    httpListeners: [
      {
        name: httpsListenerName
        properties: {
          frontendIPConfiguration: {
            id: frontendPrivateIPConfigurationID
          }
          frontendPort: {
            id: frontendIPPortID
          }
          protocol: 'https'
          hostName: domain
          sslCertificate: {
            //https://github.com/Azure/bicep/discussions/8719
            id: sslCertificateId
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: routingRuleName
        properties: {
          priority: 991
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: httpsListenerId
          }
          backendAddressPool: {
            id: uiBackendPoolId
          }
          backendHttpSettings: {
            id: httpsBackendSettingId
          }
          urlPathMap: {
            id: urlPathMapId
          }
        }
      }
    ]
    urlPathMaps: [
      {
        name: urlPathMapName
        properties: {
          defaultBackendAddressPool: {
            id: uiBackendPoolId
          }
          defaultBackendHttpSettings: {
            id: httpsBackendSettingId
          }
          pathRules: [
            {
              name: 'api'
              properties: {
                backendAddressPool: {
                  id: apiBackendPoolId
                }
                backendHttpSettings: {
                  id: httpsBackendSettingId
                }
                paths: [
                  '/api/*'
                ]
              }
            }
            {
              name: 'ui'
              properties: {
                backendAddressPool: {
                  id: uiBackendPoolId
                }
                backendHttpSettings: {
                  id: httpsBackendSettingId
                }
                paths: [
                  '/*'
                ]
              }
            }
          ]
        }
      }
    ]
    probes: [
      {
        name: probeName
        id: probeId
        properties: {
          interval: 30
          path: '/'
          pickHostNameFromBackendHttpSettings: true
          port: 443
          protocol: 'Https'
          timeout: 30
          unhealthyThreshold: 5
          match: {
            statusCodes: ['200-399', '401', '404']
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      requestBodyCheck: false
    }
  }
}

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  scope: resourceGroup(lawResouceGroupName)
  name: lawName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: applicationGateway
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

output gatewayIPID string = deploymentGatewayIP.outputs.gatewayIPID
