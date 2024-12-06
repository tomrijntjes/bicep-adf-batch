targetScope = 'subscription'

@description('Environment for deployment (test/prod)')
param environment string

@description('Location for resources')
param location string = 'westeurope'

var resourceGroupName = 'rg-data-${environment}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}
