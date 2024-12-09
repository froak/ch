param swaName string
param location string
param privateEndpointName string
param pepSubnetId string
param swaLocation string
param privateDnsZoneSubscriptionId string
param privateDnsZoneResourceGroupName string

module stapp 'modules/static_web_app.bicep' = {
  name: swaName
  params: {
    swaLocation: swaLocation
    swaName: swaName
  }
}

module privateEndpoint 'modules/private_endpoint.bicep' = {
  name: privateEndpointName
  dependsOn: [ stapp ]
  params: {
    location: location
    privateEndpointName: privateEndpointName
    privateLinkServiceId: stapp.outputs.id
    subnetId: pepSubnetId
    groupId: 'staticSites'
  }
}

module privateEndpointDnsGroup 'modules/private_dns_zone_group.bicep' = {
  name: 'privateEndpointDnsGroup'
  dependsOn: [ privateEndpoint ]
  params: {
    privateEndpointName: privateEndpointName
    zoneName: stapp.outputs.has_1_partitionId ? 'privatelink.1.azurestaticapps.net' : (stapp.outputs.has_2_partitionId ? 'privatelink.2.azurestaticapps.net' : (stapp.outputs.has_3_partitionId ? 'privatelink.3.azurestaticapps.net' : (stapp.outputs.has_4_partitionId ? 'privatelink.4.azurestaticapps.net' : (stapp.outputs.has_5_partitionId ? 'privatelink.5.azurestaticapps.net' : (stapp.outputs.has_6_partitionId ? 'privatelink.6.azurestaticapps.net' : (stapp.outputs.has_7_partitionId ? 'privatelink.7.azurestaticapps.net' : 'privatelink.azurestaticapps.net'))))))
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
  }
}
