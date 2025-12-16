metadata description = 'Creates an Azure AI Foundry Hub (AI Studio Hub).'

@description('Name of the Azure AI Hub')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('Resource ID of the Application Insights')
param applicationInsightsId string

@description('Resource ID of the Storage Account')
param storageAccountId string

@description('Resource ID of the Key Vault')
param keyVaultId string = ''

@description('Resource ID of the Container Registry (optional)')
param containerRegistryId string = ''

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

// Create Key Vault if not provided
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = if (empty(keyVaultId)) {
  name: 'kv-${take(replace(name, '-', ''), 18)}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
    publicNetworkAccess: publicNetworkAccess
  }
}

// Azure AI Hub (kind: Hub)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: name
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: name
    storageAccount: storageAccountId
    keyVault: empty(keyVaultId) ? keyVault.id : keyVaultId
    applicationInsights: applicationInsightsId
    containerRegistry: !empty(containerRegistryId) ? containerRegistryId : null
    publicNetworkAccess: publicNetworkAccess
    hbiWorkspace: false
  }
}

@description('The resource ID of the AI Hub')
output id string = aiHub.id

@description('The name of the AI Hub')
output name string = aiHub.name

@description('The principal ID of the system assigned identity')
output principalId string = aiHub.identity.principalId

@description('The discovery URL for the hub')
output discoveryUrl string = aiHub.properties.discoveryUrl
