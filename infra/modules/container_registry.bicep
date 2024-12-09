param acrName string
param location string
param acrSku string = 'Premium'
param privateEndpointName string
param privateDnsZoneName string
param subnetId string

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
    // publicNetworkAccess: 'Disabled'
    // self-hosted agent が windows で作れないので、一時的に Devops の IP から許可する箱を作っておく
    // Azure functions が pull する際に global ip から取得しに来るのと、global ip の range が広すぎるので絞れないので
    // networkRuleSet: {
    //   defaultAction: 'Deny'
    //   ipRules: []
    // }
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
          privateLinkServiceId: acrResource.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
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

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer
