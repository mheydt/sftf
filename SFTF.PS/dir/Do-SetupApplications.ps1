#
# Do_SetupApplications.ps1
#

$yourTenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$yourClusterName = "sfhack"
$region = "us-west"
$clusterDNS = $yourClusterName + "." + $region + ".cloudapp.azure.com"
$webAppUrl = "https://" + $clusterDNS + ":19080/Explorer/index.html"

.\Setup-Applications.ps1 `
	-TenantId $yourTenantId -ClusterName $clusterDNS `
	-WebApplicationReplyUrl ‘https://<your-cluster-name>.<region>.cloudapp.azure.com:19080/Explorer/index.html‘