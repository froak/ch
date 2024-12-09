param agwName string
param agwSubnetId string
param env string
param userManagedIdName string
param userManagedIdRGName string
param location string
param keyContainerName string
param keyvaultName string
param domain string
param agwPrivateIp string
param lawName string
param lawResouceGroupName string
param pipName string
param uiBackendFqdn string
param apiBackendFqdn string

module applicationGateway 'modules/application_gateway.bicep' = {
  name: agwName
  params: {
    agwName: agwName
    pipName: pipName
    agwPrivateIp: agwPrivateIp
    agwSubnetId: agwSubnetId
    domain: domain
    env: env
    keyContainerName: keyContainerName
    keyvaultName: keyvaultName
    location: location
    userManagedIdName: userManagedIdName
    userManagedIdRGName: userManagedIdRGName
    lawResouceGroupName: lawResouceGroupName
    lawName: lawName
    uiBackendFqdn: uiBackendFqdn
    apiBackendFqdn: apiBackendFqdn
  }
}
