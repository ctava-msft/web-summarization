metadata description = 'Creates an Azure AI Foundry Project.'

@description('Name of the AI Foundry Project')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('Resource ID of the AI Foundry Hub')
param hubId string

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

// Azure AI Foundry Project (kind: 'Project')
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: name
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: name
    hubResourceId: hubId
    publicNetworkAccess: publicNetworkAccess
  }
}

@description('The resource ID of the AI Project')
output id string = aiProject.id

@description('The name of the AI Project')
output name string = aiProject.name

@description('The principal ID of the system assigned identity')
output principalId string = aiProject.identity.principalId

@description('The discovery URL for the project')
output discoveryUrl string = aiProject.properties.discoveryUrl
