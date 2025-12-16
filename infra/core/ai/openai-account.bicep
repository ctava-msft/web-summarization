metadata description = 'Creates an Azure OpenAI account.'

@description('Name of the Azure OpenAI account')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('SKU name for the OpenAI account')
param skuName string = 'S0'

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Custom subdomain name')
param customSubDomainName string = name

@description('Disable local (key-based) authentication')
param disableLocalAuth bool = false

// Azure OpenAI account
resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: disableLocalAuth
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

@description('The resource ID of the OpenAI account')
output id string = openAIAccount.id

@description('The name of the OpenAI account')
output name string = openAIAccount.name

@description('The endpoint URL of the OpenAI account')
output endpoint string = openAIAccount.properties.endpoint

@description('The principal ID of the system assigned identity')
output principalId string = openAIAccount.identity.principalId

@description('The primary API key of the OpenAI account')
output key string = openAIAccount.listKeys().key1
