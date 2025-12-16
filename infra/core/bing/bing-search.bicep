metadata description = 'Creates a Bing Grounding resource.'

@description('Name of the Bing Grounding resource')
param name string

@description('Location for all resources')
param location string = 'global'

@description('Tags to apply to all resources')
param tags object = {}

@description('SKU name for the Bing Grounding API')
@allowed([
  'G1'
])
param skuName string = 'G1'

// Bing Grounding resource
resource bing 'Microsoft.Bing/accounts@2020-06-10' = {
  name: name
  location: location
  kind: 'Bing.Grounding'
  tags: (contains(tags, 'Microsoft.Bing/accounts') ? tags['Microsoft.Bing/accounts'] : json('{}'))
  sku: {
    name: skuName
  }
}

@description('The resource ID of the Bing Grounding resource')
output id string = bing.id

@description('The name of the Bing Grounding resource')
output name string = bing.name

@description('The endpoint URL of the Bing Grounding API')
output endpoint string = 'https://api.bing.microsoft.com/'

@description('The API key for Bing Grounding')
#disable-next-line outputs-should-not-contain-secrets
output apiKey string = bing.listKeys().key1
