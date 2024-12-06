targetScope = 'resourceGroup'

@description('Location for resources')
param location string

@description('Name of the Data Factory')
param dataFactoryName string

@description('Name of the Storage Account')
param storageAccountName string

@description('Id of the Storage Account')
param storageAccountId string

@secure()
@description('Id of the Storage Account')
param storageAccountKey string

@description('Environment for deployment (test/prod)')
param environment string

@description('Name of the Azure Batch account')
param batchAccountName string = 'ba${environment}'

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Define the Azure Batch account

// Define the Storage Account Linked Service
resource storageLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: 'AzureStorageLinkedService'
  properties: {
    type: 'AzureStorage'
    typeProperties: {
      connectionString: {
        type: 'SecureString'
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=${az.environment().suffixes.storage}'
      }
    }
  }
}
// Define the Azure Batch account
resource batchAccount 'Microsoft.Batch/batchAccounts@2024-02-01' = {
  name: batchAccountName
  location: location
  properties: {
    poolAllocationMode: 'BatchService'
    autoStorage: {
      storageAccountId: storageAccountId
    }
  }
}

// Define the Azure Batch pool
resource batchPool 'Microsoft.Batch/batchAccounts/pools@2023-05-01' = {
  parent: batchAccount
  name: 'BatchPool'
  properties: {
    vmSize: 'STANDARD_A4_V2' // Small VM size for testing
    deploymentConfiguration: {
      virtualMachineConfiguration: {
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
        nodeAgentSkuId: 'batch.node.ubuntu 18.04'
      }
    }
    scaleSettings: {
      autoScale: {
        formula: '''
          // Autoscale formula to start with 0 nodes and scale based on pending tasks
          pendingTaskSamples = $PendingTasks.GetSamplePercent(TimeInterval_Minute * 5);
          $TargetDedicatedNodes = max(0, min($PendingTasks.GetSample(1), 10));
        '''
        evaluationInterval: 'PT5M' // Autoscale evaluation interval
      }
    }
  }
}

resource batchLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: 'AzureBatchLinkedService'
  properties: {
    type: 'AzureBatch'
    typeProperties: {
      accessKey: {
        type: 'SecureString'
        value: batchAccount.listKeys().primary
      }
      accountName: batchAccount.name
      poolName: batchPool.name
      batchUri: 'https://${batchAccount.name}.${location}.batch.azure.com'
      linkedServiceName: {
        referenceName: storageLinkedService.name
        type: 'LinkedServiceReference'
      }
    }
  }
}

// Define the pipeline with a single Azure Batch activity
resource pipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactory
  name: 'PipelineWithBatchJob'
  properties: {
    activities: [
      {
        name: 'RunBatchJob'
        type: 'Custom'
        linkedServiceName: {
          referenceName: batchLinkedService.name
          type: 'LinkedServiceReference'
        }
        typeProperties: {
          resourceLinkedService: {
            referenceName: storageLinkedService.name
            type: 'LinkedServiceReference'
          }
          command: '/bin/bash -c "echo Hello World"'
        }
      }
    ]
  }
}
