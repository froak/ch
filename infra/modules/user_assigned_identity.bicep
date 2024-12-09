param managedIdName string
param location string

resource managedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdName
  location: location
}

// // 3. ロールの作成と割り当て

// @description('A new GUID used to identify the role assignment')
// param roleNameGuid string = guid(managedIdName)

// var role = {
//   Owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
//   Contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
//   Reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
// }

// resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: roleNameGuid
//   properties: {
//     roleDefinitionId: role['Contributor']
//     principalId: managedId.properties.principalId
//     principalType: 'ServicePrincipal'
//     // https://githubmemory.com/repo/Azure/bicep/issues/3695
//   }
// }
