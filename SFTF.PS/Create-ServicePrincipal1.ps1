#
# Create_ServicePrincipal1.ps1
#

#https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal

Login-AzureRmAccount
Add-AzureRmAccount

$yourDomain = "sfhack.westus.cloudapp.azure.com"
$appName = "myAppName"
$idUrl = "https://" + $yourDomain + "/" + $appName
$homePage = "https://$yourDomain/$appName"
$yourPassword = "myPwd"

$app = New-AzureRmADApplication -DisplayName $appName -HomePage $homePage -IdentifierUris $idUrl -Password $yourPassword
New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
Start-Sleep 15
New-AzureRmRoleAssBignment -RoleDefinitionName Reader -ServicePrincipalName $app.ApplicationId