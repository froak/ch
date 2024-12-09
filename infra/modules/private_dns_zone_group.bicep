param privateEndpointName string
param privateDnsZoneResourceGroupName string = resourceGroup().location
param privateDnsZoneSubscriptionId string
param zoneName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: zoneName
  scope: resourceGroup(privateDnsZoneSubscriptionId, privateDnsZoneResourceGroupName)
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' existing = {
  name: privateEndpointName
}

// https://blog.aimless.jp/archives/2022/07/use-integration-between-private-endpoint-and-private-dns-zone-in-bicep/
resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  name: 'dnsgroup'
  parent: privateEndpoint
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
