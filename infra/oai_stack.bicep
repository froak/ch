param name string
param location string
param oaiLocation string
param userManagedIdName string
param userManagedIdRGName string
param pepSubnetId string
param privateEndpointName string
param privateDnsZoneName string
param privateDnsZoneSubscriptionId string
param privateDnsZoneResourceGroupName string
param lawName string
param lawResouceGroupName string
param customSubDomainName string = name
param kind string = 'OpenAI'
param publicNetworkAccess string = 'Disabled'
param sku object = {
  name: 'S0'
}
param chatGptDeploymentName string = 'chat'
param chatGptModelName string = 'gpt-35-turbo'
param capacity int = 5
param version string = '0613'

param doesAccountDeploy bool
param doesDeploymentDepoly bool

module oai 'modules/cognitive_service_accounts.bicep' = if (doesAccountDeploy) {
  name: name
  params: {
    name: name
    oaiLocation: oaiLocation
    userManagedIdName: userManagedIdName
    userManagedIdRGName: userManagedIdRGName
    customSubDomainName: customSubDomainName
    kind: kind
    publicNetworkAccess: publicNetworkAccess
    sku: sku
    lawName: lawName
    lawResouceGroupName: lawResouceGroupName
  }
}

module privateEndpoint 'modules/private_endpoint.bicep' = if (doesAccountDeploy) {
  name: privateEndpointName
  dependsOn: [oai]
  params: {
    location: location
    privateEndpointName: privateEndpointName
    privateLinkServiceId: oai.outputs.id
    subnetId: pepSubnetId
    groupId: 'account'
  }
}

module privateEndpointDnsGroup 'modules/private_dns_zone_group.bicep' = if (doesAccountDeploy) {
  name: 'privateEndpointDnsGroup'
  dependsOn: [privateEndpoint]
  params: {
    privateEndpointName: privateEndpointName
    zoneName: privateDnsZoneName
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
  }
}

module deployment 'modules/cognitive_service_deployment.bicep' = if (doesDeploymentDepoly) {
  name: chatGptDeploymentName
  params: {
    name: name
    kind: kind
    chatGptDeploymentName: chatGptDeploymentName
    chatGptModelName: chatGptModelName
    capacity: capacity
    version: version
  }
}
