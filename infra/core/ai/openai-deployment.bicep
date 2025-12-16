metadata description = 'Creates an Azure OpenAI model deployment.'

@description('Name of the Azure OpenAI account')
param accountName string

@description('Name of the model deployment')
param deploymentName string

@description('Model format (e.g., OpenAI)')
param modelFormat string = 'OpenAI'

@description('Model name (e.g., gpt-5.2-chat, gpt-5.1-chat)')
param modelName string

@description('Model version')
param modelVersion string

@description('SKU name for the deployment')
param skuName string = 'GlobalStandard'

@description('SKU capacity (TPM in thousands)')
param skuCapacity int = 30

// Reference to existing OpenAI account
resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: accountName
}

// Model deployment
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  name: deploymentName
  parent: openAIAccount
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    model: {
      format: modelFormat
      name: modelName
      version: modelVersion
    }
  }
}

@description('The name of the deployment')
output name string = deployment.name

@description('The ID of the deployment')
output id string = deployment.id
