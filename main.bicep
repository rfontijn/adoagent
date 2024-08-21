// Define parameters
@description('The location where the resources will be deployed. Based on the Resource Group location.')
param location string = resourceGroup().location
@description('The name of the Azure DevOps agent pool.')
param poolName string = 'containerapp-adoagent'
@maxLength(50)
@description('The name of the Azure Container Registry.')
param containerregistryName string = 'adoregistry'
@description('The URL of the Azure DevOps organization.')
param adourl string = 'https://dev.azure.com/contoso'
// Don't include an end '/' in the URL. Else the ADO agent will fail to register.
@secure()
@description('The personal access token (PAT) used to authenticate with Azure DevOps.')
param token string
param containerappsspokevnetName string = 'containerappsspokevnet'
param vnetResourceGroup string = 'rg-zm-esb-connectivity-devtst'
param subNetName string = 'snet-zm-esb-containerapps-devtst'
@description('The name of the virtual network.')
param userassignedminame string = 'usrmi'
@description('The name of the managed environment.')
param isProduction bool = true
@description('Determines whether the environment is production or development and updates Tag accordingly.')
// Define tags
var tags = {
  environment: isProduction ? 'Production' : 'Development'
  createdBy: 'Ruben Fontijn'
}
@description('Tags to apply to the resources.')

param imagename string = 'adoagent2:1.0'
@description('The name of the container image.')
param managedenvname string = 'cnapps2'
@description('The name of the managed environment.')

// Define App Service Job resource for ADO agent
var adoagentjobName = 'adoagentjob2'

// Define virtual network resource
// var sharedServicesSubnet = {
//   name: 'sharedservices'
//   properties: {
//     addressPrefix: '172.23.5.0/23'
//   }
// }
// var containerAppsSubnet = {
//   name: 'containerappssnet'
//   properties: {
//     addressPrefix: '172.23.5.16/28'
//   }
// }
// resource containersubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
//   name: 'snet-zm-esb-adoagents'
//   parent: containerappsspokevnet
// }

resource containerAppsSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: subNetName
  parent: devVnet
}
resource devVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: containerappsspokevnetName
  scope: resourceGroup(vnetResourceGroup)
}

// resource containerappsspokevnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
//   name: containerappsspokevnetName
//   scope: resourceGroup('rg-zm-esb-connectivity-devtst')
//   location: location
//   tags: tags
//   properties: {
//     addressSpace: {
//       addressPrefixes: [ '10.0.0.0/16' ]
//     }
//     subnets: [ sharedServicesSubnet, containerAppsSubnet ]
//   }
// }
// // Define Key Vault resource
// var keyvaultName = 'keyvault-ado'
// resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' = {
//   name: keyvaultName
//   location: location
//   tags: tags
//   properties: {
//     sku: {
//       family: 'A'
//       name: 'standard'
//     }
//     tenantId: tenant().tenantId
//     networkAcls: {
//       bypass: 'AzureServices'
//       defaultAction: 'Deny'
//       ipRules: []
//       virtualNetworkRules: []
//     }
//     enableRbacAuthorization: true
//     accessPolicies: []
//     publicNetworkAccess: 'Disabled'
//     enableSoftDelete: false
//     // Change SoftDelete to True for Production
//     enabledForTemplateDeployment: true
//   }
// }
// // Define Key Vault secrets
// var kvtokensecretName = 'personal-access-token'
// resource kvtokensecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
//   name: kvtokensecretName
//   parent: keyvault
//   properties: {
//     value: token
//   }
// }
// // Define Private Endpoint resource
// var kvprivatelinkName = 'pe-${keyvaultName}'
// resource kvprivatelink 'Microsoft.Network/privateEndpoints@2023-04-01' = {
//   name: kvprivatelinkName
//   location: location
//   tags: tags
//   properties: {
//     privateLinkServiceConnections: [
//       {
//         name: 'keyvault'
//         properties: {
//           privateLinkServiceId: keyvault.id
//           groupIds: [ 'vault' ]
//         }
//       }
//     ]
//     subnet: {
//       id: sharedservicesubnet.id
//     }
//   }
// }
// // Define Private DNS Zone resource
// var keyvaultdnszoneName = 'privatelink.vaultcore.azure.net'
// resource keyvaultdnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
//   name: keyvaultdnszoneName
//   location: 'global'
// }
// // Define Private DNS Zone Group resource
// resource keyvaultprivatednszonegrp 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
//   name: keyvaultdnszoneName
//   parent: kvprivatelink
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: 'keyvault'
//         properties: {
//           privateDnsZoneId: keyvaultdnszone.id
//         }
//       }
//     ]
//   }
// }
// // Define Private DNS Zone VNet Link resource
// resource keyVaultPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
//   name: uniqueString(keyvault.id)
//   parent: keyvaultdnszone
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: containerappsspokevnet.id
//     }
//   }
// }
// // Define A record resource
// resource aarecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
//   name: keyvaultName
//   parent: keyvaultdnszone
//   properties: {
//     aRecords: [
//       {
//         ipv4Address: kvprivatelink.properties.customDnsConfigs[0].ipAddresses[0]
//       }
//     ]
//     ttl: 300
//   }
// }
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: 'log-zm-esb-common-dev'
  scope: resourceGroup('rg-zm-esb-common-dev')
}

// Define Managed Environment resource
resource cnapps 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: managedenvname
  location: location
  tags: tags

  properties: {
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
    vnetConfiguration: {
      infrastructureSubnetId: containerAppsSubnet.id
      internal: true
    }
    zoneRedundant: true
  }
}

// Define Diagnostic Settings resource
resource cnappsdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'cnappsdiag'
  scope: cnapps

  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspace.id
  }
}

// // Define Container Registry resource

resource containerregistry 'Microsoft.ContainerRegistry/registries@2023-06-01-preview' existing = {
  name: containerregistryName
  // location: location
  // tags: tags
  // identity: {
  //   type: 'UserAssigned'
  //   userAssignedIdentities: {
  //     '${usrmi.id}': {}
  //   }
  // }
  // // Identity required to allow Container Apps job to talk to the Registry.
  // sku: {
  //   name: 'Premium'
  //   //Premium is required for private endpoint support.
  // }
  // properties: {
  //   publicNetworkAccess: 'Enabled'
  //   //Required for the Deployment Scripts to build the images. Public Network access, can be disabled after.
  //   networkRuleBypassOptions: 'AzureServices'
  //   adminUserEnabled: false
}

// }

// // Define Private DNS Zone resource for Container registry

// // Define Private DNS Zone resource
// var containerregistrydnszoneName = 'privatelink.azurecr.io'

// resource containerregistrydnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
//   name: containerregistrydnszoneName
//   location: 'global'
// }

// // Define Private DNS Zone Group resource
// resource containerregistrydnszonegrp 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
//   name: containerregistrydnszoneName
//   parent: conregprivatelink
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: 'containerregistry'
//         properties: {
//           privateDnsZoneId: containerregistrydnszone.id
//         }
//       }
//     ]
//   }
// }

// // Define Private Endpoint resource
// var containerregistryprivatelinkName = 'pe-${containerregistry.name}'

// resource conregprivatelink 'Microsoft.Network/privateEndpoints@2023-04-01' = {
//   name: containerregistryprivatelinkName
//   location: location
//   tags: tags
//   properties: {
//     privateLinkServiceConnections: [
//       {
//         name: 'registry'
//         properties: {
//           privateLinkServiceId: containerregistry.id
//           groupIds: [ 'registry' ]
//         }
//       }
//     ]
//     subnet: {
//       id: sharedservicesubnet.id
//     }
//   }
// }

// // Define Private DNS Zone VNet Link resource
// resource containerregistryPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
//   name: uniqueString(containerregistry.id)
//   parent: containerregistrydnszone
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: containerappsspokevnet.id
//     }
//   }
// }

// // Define A record resource
// resource containerregistryarc 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
//   name: containerregistry.name
//   parent: containerregistrydnszone
//   properties: {
//     aRecords: [
//       {
//         ipv4Address: kvprivatelink.properties.customDnsConfigs[0].ipAddresses[0]
//       }
//     ]
//     ttl: 300
//   }
// }

// Define User Assigned Managed Identity resource
// The user managed identity associated with the container app job needs to have the following permissions to run this script:
// 1. Secret Reader to access the Key Vault secrets.
// 2. Contributor role on the container registry resource to push the container image.
// 3. Contributor role on the managed environment resource to create the job.
// 4. Contributor role on the log analytics workspace resource to enable diagnostic settings.
// 5. Contributor role on the virtual network resource to create the private endpoint.
// 6. Contributor role on the private DNS zone resource to create the A record.
// You can grant these permissions by adding the managed identity to the appropriate role assignments in Azure.

resource usrmi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userassignedminame
}

// Define Log Analytics Workspace resource
// var lawName = 'law-${uniqueString(resourceGroup().id)}'

// resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
//   name: lawName
//   location: location
//   tags: tags
//   properties: {
//     sku: {
//       name: 'PerGB2018'
//     }
//     retentionInDays: 30
//     publicNetworkAccessForIngestion: 'Enabled'
//     publicNetworkAccessForQuery: 'Enabled'
//   }
// }

// Define Deployment Script resource for ACR build
var arcbuildName = 'acrbuild'

resource arcbuild 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: arcbuildName
  location: location
  tags: tags
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${usrmi.id}': {}
    }
  }

  properties: {
    azCliVersion: '2.50.0'
    retentionInterval: 'P1D'
    timeout: 'PT30M'
    arguments: '${containerregistryName} ${imagename}'
    scriptContent: '''
    az login --identity
    az acr build --registry $1 --image $2  --file Dockerfile.azure-pipelines https://github.com/PoojithJain/containerapps-selfhosted-agent.git
    '''
    cleanupPreference: 'OnSuccess'
  }
}

// Define Deployment Script resource for ACR placeholder
var arcplaceholderName = 'arcplaceholder'

resource arcplaceholder 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: arcplaceholderName
  location: location
  tags: union(
    tags,
    {
      Note: 'Can be deleted after original ADO registration (along with the Placeholder Job). Although the Azure resource can be deleted, Agent placeholder in ADO cannot be.'
    }
  )
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${usrmi.id}': {}
    }
  }

  properties: {
    azCliVersion: '2.50.0'
    retentionInterval: 'P1D'
    timeout: 'PT30M'
    arguments: '${containerregistryName} ${imagename} ${poolName} ${resourceGroup().name} ${adourl} ${token} ${managedenvname} ${usrmi.id}'
    scriptContent: '''
    az login --identity
    az extension add --name containerapp --upgrade --only-show-errors
    az containerapp job create -n 'placeholder' -g $4 --environment $7 --trigger-type Manual --replica-timeout 300 --replica-retry-limit 1 --replica-completion-count 1 --parallelism 1 --image "$1.azurecr.io/$2" --cpu "2.0" --memory "4Gi" --secrets "personal-access-token=$6" "organization-url=$5" --env-vars "AZP_TOKEN=$6" "AZP_URL=$5" "AZP_POOL=$3" "AZP_PLACEHOLDER=1" "AZP_AGENT_NAME=dontdelete-placeholder-agent" --registry-server "$1.azurecr.io" --registry-identity "$8"  
    az containerapp job start -n "placeholder" -g $4
    '''
    cleanupPreference: 'OnSuccess'
  }
  dependsOn: [
    arcbuild
    cnapps
    cnappsdiag
  ]
}

resource adoagentjob 'Microsoft.App/jobs@2023-05-01' = {
  name: adoagentjobName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${usrmi.id}': {}
    }
  }
  properties: {
    environmentId: cnapps.id

    configuration: {
      triggerType: 'Event'

      secrets: [
        {
          name: 'personal-access-token'
          value: token
          // keyVaultUrl: kvtokensecret.properties.secretUri
          // identity: usrmi.id
        }
        {
          name: 'organization-url'
          value: adourl
        }
        {
          name: 'azp-pool'
          value: poolName
        }
      ]
      replicaTimeout: 1800
      replicaRetryLimit: 1
      eventTriggerConfig: {
        replicaCompletionCount: 1
        parallelism: 1
        scale: {
          minExecutions: 0
          maxExecutions: 10
          pollingInterval: 30
          rules: [
            {
              name: 'azure-pipelines'
              type: 'azure-pipelines'

              // https://keda.sh/docs/2.11/scalers/azure-pipelines/
              metadata: {
                poolName: poolName
                targetPipelinesQueueLength: '1'
              }
              auth: [
                {
                  secretRef: 'personal-access-token'
                  triggerParameter: 'personalAccessToken'
                }
                {
                  secretRef: 'organization-url'
                  triggerParameter: 'organizationURL'
                }
              ]
            }
          ]
        }
      }
      registries: [
        {
          server: containerregistry.properties.loginServer
          identity: usrmi.id
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${containerregistry.properties.loginServer}/adoagent2:1.0'
          name: 'adoagent2'
          env: [
            {
              name: 'AZP_TOKEN'
              secretRef: 'personal-access-token'
            }
            {
              name: 'AZP_URL'
              secretRef: 'organization-url'
            }

            {
              name: 'AZP_POOL'
              secretRef: 'azp-pool'
            }
          ]
          resources: {
            cpu: 2
            memory: '4Gi'
          }
        }
      ]
    }
  }
  dependsOn: [
    arcplaceholder
    cnappsdiag
  ]
}
