param swaName string
param swaLocation string // static web app が japaneast 対応していないので

resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: swaName
  location: swaLocation
  properties: {}
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

output id string = staticWebApp.id
output name string = staticWebApp.name
output has_1_partitionId bool = contains(staticWebApp.properties.defaultHostname, '.1.')
output has_2_partitionId bool = contains(staticWebApp.properties.defaultHostname, '.2.')
output has_3_partitionId bool = contains(staticWebApp.properties.defaultHostname, '.3.')
output has_4_partitionId bool = contains(staticWebApp.properties.defaultHostname, '.4.')
output has_5_partitionId bool = contains(staticWebApp.properties.defaultHostname, '.5.')
output has_6_partitionId bool = contains(staticWebApp.properties.defaultHostname, '.6.')
output has_7_partitionId bool = contains(staticWebApp.properties.defaultHostname, '.7.')
output has_8_partitionId bool = contains(staticWebApp.properties.defaultHostname, '.8.')
output has_9_partitionId bool = contains(staticWebApp.properties.defaultHostname, '.9.')
