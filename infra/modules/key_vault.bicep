param kvName string
param location string
param managedIdName string
param env string

resource managedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'premium'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: false // Using Access Policies model
    enabledForDeployment: true // VMs can retrieve certificates
    enabledForTemplateDeployment: true // ARM can retrieve values
    enablePurgeProtection: true // Not allowing to purge key vault or its objects after deletion
    // enableSoftDelete: true
    // softDeleteRetentionInDays: 7
    createMode: 'default' // Creating or updating the key vault (not recovering)
    publicNetworkAccess: 'Disabled'
    accessPolicies: [
      {
        objectId: '78262fb6-cb59-40d3-ac72-c4d6698c31e9' // JP-SG AZ-DI-Country-Hosting
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'all'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'import'
            'delete'
          ]
          keys: [
            'all'
          ]
        }
      }
      (env == 'DEV' || env == 'QA') ? {
        objectId: '315fa48b-c726-4666-9bd5-823d902d123a' // JP-SPN-CH--DEV-DI-Contributor
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'all'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'import'
            'delete'
          ]
          keys: [
            'all'
          ]
        }
      } : {
        objectId: '81ead4fd-f8c8-414c-8e61-35d911d63607' // JP-SPN-CH--PRD-DI-Contributor
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'all'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'import'
            'delete'
          ]
          keys: [
            'all'
          ]
        }
      }
      {
        objectId: managedId.properties.principalId // JP-UAID-sunprt-${env}-JPE 
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'all'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'import'
            'delete'
          ]
          keys: [
            'all'
          ]
        }
      }
    ]
  }
}

output keyVaultId string = keyVault.id
