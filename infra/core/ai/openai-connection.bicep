metadata description = 'Creates an Azure OpenAI connection in an AI Project workspace.'

@description('Name of the AI Project workspace')
param workspaceName string

@description('Name of the Azure OpenAI account')
param openAiAccountName string

@description('Azure OpenAI endpoint')
param openAiEndpoint string

@description('Name for the OpenAI connection')
param connectionName string = 'aoai-connection'

@description('Azure OpenAI API key')
@secure()
param openAiKey string

// Reference existing AI Project workspace
resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' existing = {
  name: workspaceName
}

// Create Azure OpenAI connection as a nested resource
resource openAiConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-04-01' = {
  name: connectionName
  parent: workspace
  properties: {
    category: 'AzureOpenAI'
    authType: 'ApiKey'
    isSharedToAll: true
    target: openAiEndpoint
    metadata: {
      ApiVersion: '2024-10-21'
      ApiType: 'Azure'
      ResourceId: resourceId('Microsoft.CognitiveServices/accounts', openAiAccountName)
    }
    credentials: {
      key: openAiKey
    }
  }
}

@description('The connection ID')
output connectionId string = openAiConnection.id

@description('The connection name')
output connectionName string = openAiConnection.name
