targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
@allowed(['australiaeast', 'eastasia', 'eastus', 'eastus2', 'northeurope', 'southcentralus', 'southeastasia', 'swedencentral', 'uksouth', 'westus2', 'eastus2euap'])
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

param resourceGroupName string = ''
param foundryName string = ''
param bingName string = ''
param modelDeploymentName string = ''
param modelName string = ''
param modelVersion string = ''
param modelCapacity int = 0

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location, 'v4'))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Azure AI Foundry (unified resource with built-in project)
module foundry './core/ai/foundry.bicep' = {
  name: 'foundry'
  scope: rg
  params: {
    foundryName: !empty(foundryName) ? foundryName : 'mlw-foundry-${resourceToken}'
    bingName: !empty(bingName) ? bingName : 'cog-bing-${resourceToken}'
    location: location
    modelDeploymentName: !empty(modelDeploymentName) ? modelDeploymentName : 'gpt-5.2-chat'
    modelName: !empty(modelName) ? modelName : 'gpt-5.2-chat'
    modelVersion: !empty(modelVersion) ? modelVersion : '2025-12-11'
    modelCapacity: modelCapacity != 0 ? modelCapacity : 110
  }
}

// App outputs
output AZURE_AI_PROJECT_ENDPOINT string = foundry.outputs.projectEndpoint
output AI_PROJECT_NAME string = 'proj-default'
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_TENANT_ID string = tenant().tenantId
output FOUNDRY_ACCOUNT_NAME string = foundry.outputs.foundryAccountName
output FOUNDRY_ENDPOINT string = foundry.outputs.foundryEndpoint
output MODEL_DEPLOYMENT_NAME string = foundry.outputs.modelDeploymentName
output BING_CONNECTION_ID string = foundry.outputs.bingConnectionId
output BING_CONNECTION_NAME string = foundry.outputs.bingConnectionName
