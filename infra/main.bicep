@description('The name of the environment. This must be dev, test, or prod.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('The unique name of the solution. This is used to ensure that resource names are unique.')
@minLength(5)
@maxLength(30)
param solutionName string = 'todo-app-${uniqueString(resourceGroup().id)}'

@description('The Azure region into which the resources should be deployed.')
param location string = 'westeurope'

@secure
@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@secure
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorPassword string

var appServicePlanName = '${environmentName}-${solutionName}-plan'
var appServiceAppName = '${environmentName}-${solutionName}-app'
var sqlServerName = '${environmentName}-${solutionName}-sql'
var sqlDatabaseName = 'mssqllocaldb'

resource appServicePlan 'Microsoft.Web/serverFarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    tier: 'Standard'  // Which features are available
    name: 'S1'        // Size of the VM (S1 = 1 CPU Core, 1.75GB RAM)
  }
  properties: {
    reserved: true
  }
  kind: 'linux'
}

resource appServiceApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
    }
  }
}

resource appServiceAppConnStrings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'connectionstrings'
  kind: 'string'
  parent: appServiceApp
  properties: {
    MyDbConnection: {
      value: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};User Id=${sqlServer.properties.administratorLogin}@${sqlServer.properties.fullyQualifiedDomainName};Password=${sqlServerAdministratorPassword};'
      type: 'SQLAzure'
    }
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorPassword
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource allowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2022-02-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource allowDeploymentServerIps 'Microsoft.Sql/servers/firewallRules@2022-02-01-preview' = {
  name: 'AllowDeploymentServerIps'
  parent: sqlServer
  properties: {
    endIpAddress: '81.207.159.218'
    startIpAddress: '81.207.159.218'
  }
}
