param ddosProtectionPlanName string
param location string

resource symbolicname 'Microsoft.Network/ddosProtectionPlans@2022-07-01' = {
  name: ddosProtectionPlanName
  location: location
  properties: {}
}
