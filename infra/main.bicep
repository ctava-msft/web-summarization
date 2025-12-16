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
param aiProjectName string = ''
param openAIAccountName string = ''
param gpt52ChatDeploymentName string = 'gpt-52-chat'
param bingSearchName string = ''
param principalId string = ''
param applicationInsightsName string = ''
param logAnalyticsName string = ''
param storageAccountName string = ''
param userManagedIdentityName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location, 'v4'))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// User-assigned managed identity for application
module userIdentity './core/identity/userAssignedIdentity.bicep' = {
  name: 'userIdentity'
  scope: rg
  params: {
    location: location
    tags: tags
    identityName: !empty(userManagedIdentityName) ? userManagedIdentityName : '${abbrs.managedIdentityUserAssignedIdentities}app-${resourceToken}'
  }
}

// Monitor application with Azure Monitor (required for AI Project)
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    disableLocalAuth: false
  }
}

// Backing storage (required for AI Foundry)
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
    containers: []
    publicNetworkAccess: 'Enabled'
    allowSharedKeyAccess: true
  }
}

// Azure AI Foundry Hub (required for Foundry Project)
module aiHub './core/ai/ai-hub.bicep' = {
  name: 'aiHub'
  scope: rg
  params: {
    name: '${abbrs.machineLearningServicesWorkspaces}hub-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsId: monitoring.outputs.applicationInsightsId
    storageAccountId: storage.outputs.id
    publicNetworkAccess: 'Enabled'
  }
}

// Azure AI Foundry Project (with hub)
module aiProject './core/ai/ai-project.bicep' = {
  name: 'aiProject'
  scope: rg
  params: {
    name: !empty(aiProjectName) ? aiProjectName : '${abbrs.machineLearningServicesWorkspaces}project-${resourceToken}'
    location: location
    tags: tags
    hubId: aiHub.outputs.id
    publicNetworkAccess: 'Enabled'
  }
}

// Azure OpenAI Account
module openAIAccount './core/ai/openai-account.bicep' = {
  name: 'openAIAccount'
  scope: rg
  params: {
    name: !empty(openAIAccountName) ? openAIAccountName : 'openai-${resourceToken}'
    location: location
    tags: tags
    customSubDomainName: !empty(openAIAccountName) ? openAIAccountName : 'openai-${resourceToken}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false  // Enable key-based authentication
  }
}

// GPT-5.2-chat Model Deployment (for summarization)
module gpt52ChatDeployment './core/ai/openai-deployment.bicep' = {
  name: 'gpt52ChatDeployment'
  scope: rg
  params: {
    accountName: openAIAccount.outputs.name
    deploymentName: gpt52ChatDeploymentName
    modelName: 'gpt-5.2-chat'
    modelVersion: '2025-12-11'
    skuCapacity: 30
  }
}

// Bing Grounding API (for web search grounding)
module bingGrounding './core/bing/bing-search.bicep' = {
  name: 'bingGrounding'
  scope: rg
  params: {
    name: !empty(bingSearchName) ? bingSearchName : '${abbrs.cognitiveServicesAccounts}bing-${resourceToken}'
    location: 'global'
    tags: tags
    skuName: 'G1'
  }
}

// Create Azure OpenAI connection in AI Project
module openAiConnection './core/ai/openai-connection.bicep' = {
  name: 'openAiConnection'
  scope: rg
  params: {
    workspaceName: aiProject.outputs.name
    openAiAccountName: openAIAccount.outputs.name
    openAiEndpoint: openAIAccount.outputs.endpoint
    openAiKey: openAIAccount.outputs.key
    connectionName: 'aoai-connection'
  }
}

// Create Bing Grounding connection in AI Project
module bingConnection './core/ai/bing-connection.bicep' = {
  name: 'bingConnection'
  scope: rg
  params: {
    workspaceName: aiProject.outputs.name
    bingResourceName: bingGrounding.outputs.name
    connectionName: 'bing-grounding-connection'
    location: 'global'
  }
}

// Role definitions
var CognitiveServicesOpenAIUser = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User role ID

// Allow access from user-assigned managed identity to Azure OpenAI
module openAIRoleAssignmentManagedIdentity './core/ai/openai-access.bicep' = {
  name: 'openAIRoleAssignmentManagedIdentity'
  scope: rg
  params: {
    accountName: openAIAccount.outputs.name
    roleDefinitionID: CognitiveServicesOpenAIUser
    principalID: userIdentity.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Allow access from current user to Azure OpenAI (for local development)
module openAIRoleAssignmentUser './core/ai/openai-access.bicep' = if (!empty(principalId)) {
  name: 'openAIRoleAssignmentUser'
  scope: rg
  params: {
    accountName: openAIAccount.outputs.name
    roleDefinitionID: CognitiveServicesOpenAIUser
    principalID: principalId
    principalType: 'User'
  }
}

// App outputs
output AI_PROJECT_NAME string = aiProject.outputs.name
output AZURE_LOCATION string = location
output AZURE_OPENAI_ACCOUNT_NAME string = openAIAccount.outputs.name
output AZURE_OPENAI_ENDPOINT string = openAIAccount.outputs.endpoint
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_TENANT_ID string = tenant().tenantId
output GPT52_CHAT_DEPLOYMENT_NAME string = gpt52ChatDeployment.outputs.name
output AZURE_CLIENT_ID string = userIdentity.outputs.identityClientId
output USER_MANAGED_IDENTITY_CLIENT_ID string = userIdentity.outputs.identityClientId
output BING_SEARCH_ENDPOINT string = bingGrounding.outputs.endpoint
output BING_SEARCH_KEY string = bingGrounding.outputs.apiKey
output BING_SEARCH_NAME string = bingGrounding.outputs.name
output BING_CONNECTION_ID string = bingConnection.outputs.connectionId
output BING_CONNECTION_NAME string = bingConnection.outputs.connectionName
