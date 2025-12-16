metadata description = 'Creates a secret in Azure Key Vault.'

@description('Name of the Key Vault')
param keyVaultName string

@description('Name of the secret')
param secretName string

@description('Value of the secret')
@secure()
param secretValue string

@description('Tags to apply to the secret')
param tags object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: secretName
  tags: tags
  properties: {
    value: secretValue
  }
}

@description('The name of the secret')
output secretName string = secret.name

@description('The URI of the secret')
output secretUri string = secret.properties.secretUri

@description('The URI with version of the secret')
output secretUriWithVersion string = secret.properties.secretUriWithVersion
