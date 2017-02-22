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
$certificateThumbprint = "C7F88BBF8DD2FA3BB461F11B3F6C8C7B67BA1FE0"

# Login to Azure
Login-AzureRmAccount

# Compute the cluster endpoint (note, change port here is you change the default in the parameters)
$connectionEndpoint = "$clusterName.$location.cloudapp.azure.com:19000"

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

# Print Connection details
Write-Output "Connection Endpoint : $connectionEndpoint"
Write-Output "Certificate Thumbprint : $certificateThumbprint"
