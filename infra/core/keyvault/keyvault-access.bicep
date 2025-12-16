metadata description = 'Assigns a role to a principal on an Azure Key Vault.'

@description('Name of the Key Vault')
param keyVaultName string

@description('Role definition ID to assign')
param roleDefinitionID string

@description('Principal ID to assign the role to')
param principalID string

@description('Principal type (User, Group, or ServicePrincipal)')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param principalType string = 'ServicePrincipal'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, principalID, roleDefinitionID)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
    principalId: principalID
    principalType: principalType
  }
}
