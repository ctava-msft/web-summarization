param principalID string
param roleDefinitionID string
param accountName string
param principalType string = 'ServicePrincipal'

resource cognitiveAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: accountName
}

// Allow access from API to Azure OpenAI using a managed identity
resource openAIRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(cognitiveAccount.id, principalID, roleDefinitionID)
  scope: cognitiveAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
    principalId: principalID
    principalType: principalType
  }
}

output ROLE_ASSIGNMENT_NAME string = openAIRoleAssignment.name
