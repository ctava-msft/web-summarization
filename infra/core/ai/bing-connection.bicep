metadata description = 'Creates a Bing Grounding connection in an AI Project workspace.'

@description('Name of the AI Project workspace')
param workspaceName string

@description('Name of the Bing Grounding resource')
param bingResourceName string

@description('Name for the Bing connection')
param connectionName string = 'bing-grounding-connection'

@description('Location for the connection')
param location string = 'global'

// Reference existing Bing Grounding resource
resource bing 'Microsoft.Bing/accounts@2020-06-10' existing = {
  name: bingResourceName
}

// Reference existing AI Project workspace
resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' existing = {
  name: workspaceName
}

// Create Bing Grounding connection as a nested resource
resource bingConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-01-01-preview' = {
  name: connectionName
  parent: workspace
  properties: {
    category: 'ApiKey'
    authType: 'ApiKey'
    isSharedToAll: true
    target: 'https://api.bing.microsoft.com/'
    credentials: {
      key: bing.listKeys().key1
    }
    metadata: {
      location: location
    }
  }
}

@description('The connection ID in the format required by Azure AI Agent Service')
output connectionId string = bingConnection.id

@description('The connection name')
output connectionName string = bingConnection.name
