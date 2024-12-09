param location string
param env string
param vnetId string
param pepSubnetId string

param internalStorageAccountName string
param kvName string

param managedIdName string
param logAnalyticsWorkspaceName string

param internalBlobPrivateEndpointName string
param internalFilePrivateEndpointName string
param internalQueuePrivateEndpointName string
param internalTablePrivateEndpointName string
param kvPrivateEndpointName string

param privateDnsZoneSubscriptionId string
param privateDnsZoneResourceGroupName string
param privateDnsZoneBlob string
param privateDnsZoneFile string
param privateDnsZoneQueue string
param privateDnsZoneTable string
param privateDnsZoneKeyVault string
param privateDnsZoneAic string

var skuName = 'Standard_LRS'
var kind = 'StorageV2'

var domainNames = [
  toLower('${privateDnsZoneAic}')
]

module privateDns 'modules/private_dns.bicep' = [for domainName in domainNames: {
  name: 'privateDns-${domainName}'
  params: {
    vnetId: vnetId
    domainName: domainName
  }
}]

module internalStorageAccount 'modules/storage_account.bicep' = {
  name: 'internalStorageAccount'
  params: {
    storageModuleAccountName: internalStorageAccountName
    location: location
    skuName: skuName
    kind: kind
  }
}

module internalStorageAccountResources 'modules/storage_account_blob.bicep' = {
  dependsOn: [ internalStorageAccount ]
  name: 'internalStorageAccountResources'
  params: {
    storageModuleAccountName: internalStorageAccountName
    containerNames: [ 'modules' ]
  }
}

module internalStorageAccountBlobPEP 'modules/private_endpoint.bicep' = {
  dependsOn: [ internalStorageAccount ]
  name: 'internalStorageAccountBlobPEP'
  params: {
    location: location
    privateEndpointName: internalBlobPrivateEndpointName
    privateLinkServiceId: internalStorageAccount.outputs.storageAccountId
    subnetId: pepSubnetId
    groupId: 'BLOB'
  }
}

module internalStorageAccountBlobPrivateDnsZoneGroup 'modules/private_dns_zone_group.bicep' = {
  name: 'internalStorageAccountBlobPrivateDnsZoneGroup'
  dependsOn: [ internalStorageAccountBlobPEP ]
  params: {
    privateEndpointName: internalBlobPrivateEndpointName
    zoneName: privateDnsZoneBlob
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
  }
}

module internalStorageAccountFileservice 'modules/storage_account_fileservice.bicep' = {
  dependsOn: [ internalStorageAccount ]
  name: 'internalStorageAccountFile'
  params: {
    storageAccountName: internalStorageAccountName
  }
}

module internalStorageAccountFilePEP 'modules/private_endpoint.bicep' = {
  dependsOn: [ internalStorageAccount ]
  name: 'internalStorageAccountFilePEP'
  params: {
    location: location
    privateEndpointName: internalFilePrivateEndpointName
    privateLinkServiceId: internalStorageAccount.outputs.storageAccountId
    subnetId: pepSubnetId
    groupId: 'File'
  }
}

module internalStorageAccountFilePrivateDnsZoneGroup 'modules/private_dns_zone_group.bicep' = {
  name: 'internalStorageAccountFilePrivateDnsZoneGroup'
  dependsOn: [ internalStorageAccountFilePEP ]
  params: {
    privateEndpointName: internalFilePrivateEndpointName
    zoneName: privateDnsZoneFile
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
  }
}

module internalStorageAccountQueuePEP 'modules/private_endpoint.bicep' = {
  dependsOn: [ internalStorageAccount ]
  name: 'internalStorageAccountQueuePEP'
  params: {
    location: location
    privateEndpointName: internalQueuePrivateEndpointName
    privateLinkServiceId: internalStorageAccount.outputs.storageAccountId
    subnetId: pepSubnetId
    groupId: 'Queue'
  }
}

module internalStorageAccountQueuePrivateDnsZoneGroup 'modules/private_dns_zone_group.bicep' = {
  name: 'internalStorageAccountQueuePrivateDnsZoneGroup'
  dependsOn: [ internalStorageAccountQueuePEP ]
  params: {
    privateEndpointName: internalQueuePrivateEndpointName
    zoneName: privateDnsZoneQueue
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
  }
}

module internalStorageAccountTablePEP 'modules/private_endpoint.bicep' = {
  dependsOn: [ internalStorageAccount ]
  name: 'internalStorageAccountTablePEP'
  params: {
    location: location
    privateEndpointName: internalTablePrivateEndpointName
    privateLinkServiceId: internalStorageAccount.outputs.storageAccountId
    subnetId: pepSubnetId
    groupId: 'Table'
  }
}

module internalStorageAccountTablePrivateDnsZoneGroup 'modules/private_dns_zone_group.bicep' = {
  name: 'internalStorageAccountTablePrivateDnsZoneGroup'
  dependsOn: [ internalStorageAccountTablePEP ]
  params: {
    privateEndpointName: internalTablePrivateEndpointName
    zoneName: privateDnsZoneTable
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
  }
}

module userAssignedIdentity 'modules/user_assigned_identity.bicep' = {
  name: 'userAssignedIdentity'
  params: {
    managedIdName: managedIdName
    location: location
  }
}

module keyVault 'modules/key_vault.bicep' = {
  dependsOn: [ userAssignedIdentity ]
  name: 'keyVault'
  params: {
    kvName: kvName
    location: location
    managedIdName: managedIdName
    env: env
  }
}

module kvPEP 'modules/private_endpoint.bicep' = {
  name: 'kvPEP'
  params: {
    location: location
    privateEndpointName: kvPrivateEndpointName
    privateLinkServiceId: keyVault.outputs.keyVaultId
    subnetId: pepSubnetId
    groupId: 'vault'
  }
}

module kvPrivateDnsZoneGroup 'modules/private_dns_zone_group.bicep' = {
  name: 'kvPrivateDnsZoneGroup'
  dependsOn: [ kvPEP ]
  params: {
    privateEndpointName: kvPrivateEndpointName
    zoneName: privateDnsZoneKeyVault
    privateDnsZoneResourceGroupName: privateDnsZoneResourceGroupName
    privateDnsZoneSubscriptionId: privateDnsZoneSubscriptionId
  }
}

module law 'modules/log_analytics_workspace.bicep' = {
  name: 'law'
  params: {
    location: location
    workspaceName: logAnalyticsWorkspaceName
  }
}
