@description('Environment')
param environment string

@description('Key Vault Name')
param keyVaultName string

@description('Client ID of service principal to be associated with Azure Keyvault Service')
param spnClientID string

@description('Client ID of portal user to be associated with Azure Keyvault Service')
param userObjectID string

@description('Data Factory Name')
param dataFactoryName string

@description('Storage SKU')
param storageSKU string

@description('Location of the data factory.')
param location string = resourceGroup().location

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string

@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'blob${uniqueString(resourceGroup().id)}'

@description('Conditional resource creation')
param deployStorage bool
param deployADF bool

@description('Git Type.')
param gitType string = ' '
var _repositoryType = (gitType == 'AzureDevOps') ? 'FactoryVSTSConfiguration' : 'FactoryGitHubConfiguration'

@description('Name of the Git Account.')
param gitAccount string = ' '

@description('Git Project.')
param gitProject string = ' '
var _gitProject = (gitType == 'AzureDevOps') ? gitProject: ' '


@description('Name of the Git Repository.')
param gitRepo string = ' '

@description('Name of the Git Collaboration Branch.')
param gitCollab string = ' '

@description('Name of the Git Root Folder.')
param gitFolder string = ' '

@description('Name of the Databricks workspace.')
param databricksWorkspaceName string

@description('Location of the Databricks workspace.')
param databricksWorkspaceLocation string = resourceGroup().location


var azDevopsRepoConfiguration = {
  accountName: gitAccount
  repositoryName: gitRepo
  collaborationBranch: gitCollab
  rootFolder: gitFolder  
  type: _repositoryType
  projectName: _gitProject
}

var gitHubRepoConfiguration = {
  accountName: gitAccount
  repositoryName: gitRepo
  collaborationBranch: gitCollab
  rootFolder: gitFolder  
  type: _repositoryType
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = if (deployStorage) {
  name: storageAccountName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = if (deployStorage) {
  name: '${storageAccount.name}/default/${blobContainerName}'
}

resource dataFactoryName_resource 'Microsoft.DataFactory/factories@2018-06-01' = if (deployADF) {
  name: dataFactoryName
  location: location
  properties: {
    repoConfiguration: (environment == 'development') ? (gitType == 'AzureDevOps') ? azDevopsRepoConfiguration : gitHubRepoConfiguration : {}
  }
  identity: {
  type: 'SystemAssigned'
}
}

//var datafactory_principal_id string = dataFactoryName_resource.identity.principalId


resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  properties: {
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
//  enableSoftDelete: true
//  enableRbacAuthorization: true
//  enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
        accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: spnClientID
        permissions: {
            keys: [
                'all'
            ]
            secrets: [
                'all'
            ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: userObjectID
        permissions: {
            keys: [
                'all'
            ]
            secrets: [
                'all'
            ]
        }
      }
      {
          tenantId: subscription().tenantId
          objectId: dataFactoryName_resource.identity.principalId
          permissions: {
              secrets: [
                  'get'
                  'list'
              ]
          }
      }
    ]
  }
}


resource databricksWorkspace 'Microsoft.Databricks/workspaces@2021-04-01' = {
  name: databricksWorkspaceName
  location: location
  sku: {
    name: 'standard'
  }
  properties: {
    managedResourceGroupName: resourceGroup().name
    parameters: {
      customParameters: {}
      encryption: {
        enabled: true
      }
      publicNetworkAccess: {
        enabled: false
      }
    }
  }
}
