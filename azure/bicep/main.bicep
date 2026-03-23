param location string = resourceGroup().location
param appName string = 'retail-shelf-webapp'
param acrName string = 'retailshelfacr${uniqueString(resourceGroup().id)}'
param planName string = 'retail-shelf-plan'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: planName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'retailshelf${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acr.properties.loginServer}/retail-app:latest'
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'APP_ENV'
          value: 'prod'
        }
        {
          name: 'LOG_LEVEL'
          value: 'INFO'
        }
      ]
    }
    httpsOnly: true
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output acrLoginServer string = acr.properties.loginServer
