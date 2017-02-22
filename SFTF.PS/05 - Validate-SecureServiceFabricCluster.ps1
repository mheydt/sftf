#
# Validate_ServiceFabricCluster.ps1
#
# Validates being able to connect to a Service Fabric cluster
#

# The name of your Service Fabric cluster
$clusterName = "mysfcluster1"

# Which region of azure?
$location = "westus"

# Replace with the thumbprint of your certificate.  This is for mysfcluster1.pfx
$certificateThumbprint = "812508463AE35AF784956315D3414DF1854CF8A6"

# Set the Subscription ID; needed if you have more than one - and you need to change to yours
$subscriptionId = "b02264bc-1ea4-4849-abb9-60b5293ed558" 

# Compute the cluster endpoint (note, change port here is you change the default in the parameters)
$connectionEndpoint = "$clusterName.$location.cloudapp.azure.com:19000"

Write-Host "Your connection endpoint is:"
Write-Host $connectionEndpoint

# Login to Azure
Login-AzureRmAccount

# If more than one under your account, you need to specify the specific subscription id
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Try and connect to the cluster with all the info that we have
Connect-serviceFabricCluster -ConnectionEndpoint $connectionEndpoint -KeepAliveIntervalInSec 10 `
	-X509Credential `
	-ServerCertThumbprint $certificateThumbprint `
	-FindType FindByThumbprint `
	-FindValue $certificateThumbprint `
	-StoreLocation CurrentUser `
	-StoreName My

# Get cluster health and other checks    
Get-ServiceFabricNode | Format-Table -AutoSize
Get-ServiceFabricService fabric:/System | Format-Table -AutoSize
