param principalID string
param roleDefinitionID string
param workspaceName string

resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' existing = {
  name: workspaceName
}

// Allow access from API to AI Project using a managed identity
resource workspaceRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(workspace.id, principalID, roleDefinitionID)
  scope: workspace
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
    principalId: principalID
    principalType: 'ServicePrincipal'
  }
}

output ROLE_ASSIGNMENT_NAME string = workspaceRoleAssignment.name
