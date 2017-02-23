# Resource group for the Key-Vault service. 
$resourceGroup = "sfhackRG" 

$clusterName = "mikeheydtsf"

# Name of the Key Vault service
$keyVaultName = "sfhackKV" 

# Set the Subscription ID; needed if you have more than one - and you need to change to yours
$subscriptionId = "15b8ace7-90d7-4555-820a-acefe105886b" 

# Specify the region to locate the keyvault
$location = "West US"

# AAD tenantID
$tenantID = "211cccfd-ace0-4d82-91ff-7b82ca3dc67b"

# The certificate that you want to add
# Note that if you are going to use this as authentication to a Service Fabric cluster,
# the DNS in the certificate must match the name of that cluster's FQDN
$certFileFullPath = "$PSScriptRoot/certs/mikeheydtsf.pfx"

$webAppUrl = "$clusterName.cloudapp.azure.com:19080/Explorer/index.html"


# log into azure
#Login-AzureRmAccount

# If more than one under your account, you need to specify the specific subscription id
#$sub = Select-AzureRmSubscription -SubscriptionId $subscriptionId

$appInfo = . "$PSScriptRoot\graphapi\SetupApplication.ps1" -TenantId $tenantID -ClusterName $clusterName -WebApplicationReplyUrl $webAppUrl
$appInfo
