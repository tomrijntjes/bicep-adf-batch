targetScope = 'resourceGroup'

@description('Environment for deployment (test/prod)')
param environment string

@description('Location for resources')
param location string = 'westeurope'

var dataFactoryName = 'df-${environment}'
var storageAccountName = environment == 'test' ? 'datalaketest' : 'datalakeprod'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    isHnsEnabled: true // Enable hierarchical namespace for ADLS
  }
}
module deployDataFactory 'data-factory.bicep' = {
  name: 'deployDataFactoryToRg'
  params: {
    location: location
    dataFactoryName: dataFactoryName
    storageAccountName: storageAccount.name
    storageAccountId: storageAccount.id
    environment: environment
    storageAccountKey: storageAccount.listKeys().keys[0].value
  }
}
