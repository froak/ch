param location string
param pepSubnetId string

param moduleStorageAccountName string

param mdlBlobPrivateEndpointName string
param mdlFilePrivateEndpointName string

param privateDnsZoneSubscriptionId string
param privateDnsZoneResourceGroupName string
param privateDnsZoneBlob string
param privateDnsZoneFile string

var skuName = 'Standard_LRS'
var kind = 'StorageV2'
var containerNames = [
  'builds'
]

module mdlStorageAccount 'modules/storage_account.bicep' = {
  name: 'moduleStorageAccount'
  params: {
    storageModuleAccountName: moduleStorageAccountName
    location: location
    skuName: skuName
    kind: kind
    publicNetworkAccess: 'Disabled'
    allowSharedKeyAccess: false
  }
}

module mdlStorageAccountResources 'modules/storage_account_blob.bicep' = {
  dependsOn: [ mdlStorageAccount ]
  name: 'storageAccountResources'
  params: {
    storageModuleAccountName: moduleStorageAccountName
    containerNames: containerNames
  }
}

module mdlStorageAccountBlobPEP 'modules/private_endpoint.bicep' = {
  name: 'mdlStorageAccountBlobPEP'
  params: {
    location: location
    privateEndpointName: mdlBlobPrivateEndpointName
    privateLinkServiceId: mdlStorageAccount.outputs.storageAccountId
    subnetId: pepSubnetId
    groupId: 'BLOB'
  }
}

module mdlStorageAccountBlobPrivateDnsZoneGroup 'modules/private_dns_zone_group.bicep' = {
  name: 'mdlStorageAccountBlobPrivateDnsZoneGroup'
  dependsOn: [ mdlStorageAccountBlobPEP ]
  params: {
    privateEndpointName: mdlBlobPrivateEndpointName
    zoneName: privateDnsZoneBlob
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
  }
}

module mdlStorageAccountFileservice 'modules/storage_account_fileservice.bicep' = {
  dependsOn: [ mdlStorageAccount ]
  name: 'mdlStorageAccountFileservice'
  params: {
    storageAccountName: moduleStorageAccountName
  }
}

module mdlStorageAccountFilePEP 'modules/private_endpoint.bicep' = {
  dependsOn: [ mdlStorageAccount ]
  name: 'mdlStorageAccountFilePEP'
  params: {
    location: location
    privateEndpointName: mdlFilePrivateEndpointName
    privateLinkServiceId: mdlStorageAccount.outputs.storageAccountId
    subnetId: pepSubnetId
    groupId: 'File'
  }
}

module mdlStorageAccountFilePrivateDnsZoneGroup 'modules/private_dns_zone_group.bicep' = {
  name: 'mdlStorageAccountFilePrivateDnsZoneGroup'
  dependsOn: [ mdlStorageAccountFilePEP ]
  params: {
    privateEndpointName: mdlFilePrivateEndpointName
    zoneName: privateDnsZoneFile
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
  }
}
