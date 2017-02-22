﻿# This module does the heavy lifting
Import-Module "$ENV:ProgramFiles\Microsoft SDKs\Service Fabric\Tools\PSModule\ServiceFabricSDK\ServiceFabricSDK.psm1"

# Replace with the thumbprint of your certificate.  This is for mysfcluster1.pfx
$certificateThumbprint = "C7F88BBF8DD2FA3BB461F11B3F6C8C7B67BA1FE0"

# A prepackaged app
# Or you can use the solution app if you zip the pkg SFTF/pkg/Debug folder and change the extension to .sfpkg
# WordCount app has two versions so you can play with versioning (WordCountV1.sfpkg and WordCountV2.sfpkg)
$packageFile = "$PSScriptRoot/pkg/WordCountV1.sfpkg"
$applicationName = "fabric:/WordCount"

Login-AzureRmAccount

Connect-serviceFabricCluster -ConnectionEndpoint $connectionEndpoint -KeepAliveIntervalInSec 10 `
	-X509Credential `
	-ServerCertThumbprint $certificateThumbprint `
	-FindType FindByThumbprint `
	-FindValue $certificateThumbprint `
	-StoreLocation CurrentUser `
	-StoreName My

Publish-NewServiceFabricApplication -ApplicationPackagePath $packageFile -ApplicationName $applicationName

# To upgrade, use the following
# Publish-UpgradedServiceFabricApplication -ApplicationPackagePath $packageFile -ApplicationName $applicationName -UpgradeParameters @{"FailureAction"="Rollback"; "UpgradeReplicaSetCheckTimeout"=1; "Monitored"=$true; "Force"=$true}