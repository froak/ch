// parameters for functions
param env string
param location string
param functionName string
param modulePath string
param connectionString string
param pepSubnetId string
param outboundSubnetId string
param lawName string
param lawResouceGroupName string
param privateEndpointName string
param privateDnsZoneSubscriptionId string
param privateDnsZoneResourceGroupName string
param privateDnsZoneName string
param userManagedIdName string
param userManagedIdRGName string
param applicationClientId string
param internalStorageAccountResouceGroupName string
param internalStorageAccountName string
param oaiNameChatBasic string
param oaiNameChatAdvance string
param oaiChatBasicModelName string
param oaiChatAdvanceModelName string

// param oaiNameChatWithFile string
// param oaiNameTranslate string

module fileShare 'modules/storage_account_share.bicep' = {
  name: 'fileShare'
  scope: resourceGroup(internalStorageAccountResouceGroupName)
  params: {
    shareName: toLower(functionName)
    storageAccountName: internalStorageAccountName
  }
}

module function 'modules/function_app.bicep' = {
  dependsOn: [fileShare]
  name: functionName
  params: {
    env: env
    funcName: functionName
    connectionString: connectionString
    modulePath: modulePath
    outboundSubnetId: outboundSubnetId
    location: location
    lawName: lawName
    lawResouceGroupName: lawResouceGroupName
    userManagedIdName: userManagedIdName
    userManagedIdRGName: userManagedIdRGName
    applicationClientId: applicationClientId
    oaiNameChatBasic: oaiNameChatBasic
    oaiNameChatAdvance: oaiNameChatAdvance
    // oaiNameChatWithFile: oaiNameChatWithFile
    // oaiNameTranslate: oaiNameTranslate
    oaiChatBasicModelName: oaiChatBasicModelName
    oaiChatAdvanceModelName: oaiChatAdvanceModelName
  }
}

module privateEndpoint 'modules/private_endpoint.bicep' = {
  name: privateEndpointName
  dependsOn: [function]
  params: {
    location: location
    privateEndpointName: privateEndpointName
    privateLinkServiceId: function.outputs.id
    subnetId: pepSubnetId
    groupId: 'sites'
  }
}

module privateEndpointDnsGroup 'modules/private_dns_zone_group.bicep' = {
  name: 'privateEndpointDnsGroup'
  dependsOn: [privateEndpoint]
  params: {
    privateEndpointName: privateEndpointName
    zoneName: privateDnsZoneName
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
  }
}
