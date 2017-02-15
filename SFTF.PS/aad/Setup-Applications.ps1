$yourClusterName = "sfhack"
$region = "us-west"

$TenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$ClusterName = $yourClusterName + "." + "$region" + ".us-west.cloudapp.azure.com"
$WebApplicationReplyUrl = "https://" + $clusterDNS + ":19080/Explorer/index.html"

Write-Host 'TenantId = ' $TenantId

. "$PSScriptRoot\Common.ps1"

$graphAPIFormat = $resourceUrl + "/" + $TenantId + "/{0}?api-version=1.5"
$ConfigObj = @{}
$ConfigObj.TenantId = $TenantId

$appRole = 
@{
    allowedMemberTypes = @("User")
    description = "ReadOnly roles have limited query access"
    displayName = "ReadOnly"
    id = [guid]::NewGuid()
    isEnabled = "true"
    value = "User"
},
@{
    allowedMemberTypes = @("User")
    description = "Admins can manage roles and perform all task actions"
    displayName = "Admin"
    id = [guid]::NewGuid()
    isEnabled = "true"
    value = "Admin"
}

$requiredResourceAccess =
@(@{
    resourceAppId = "00000002-0000-0000-c000-000000000000"
    resourceAccess = @(@{
        id = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
        type= "Scope"
    })
})

if (!$WebApplicationName)
{
	$WebApplicationName = "ServiceFabricCluster"
}

if (!$WebApplicationUri)
{
	$WebApplicationUri = "https://ServiceFabricCluster"
}

if (!$NativeClientApplicationName)
{
	$NativeClientApplicationName =  "ServiceFabricClusterNativeClient"
}

#Create Web Application
$uri = [string]::Format($graphAPIFormat, "applications")
$webApp = @{
    displayName = $WebApplicationName
    identifierUris = @($WebApplicationUri)
    homepage = $WebApplicationReplyUrl #Not functionally needed. Set by default to avoid AAD portal UI displaying error
    replyUrls = @($WebApplicationReplyUrl)
    appRoles = $appRole
}

switch ($Location)
{
    "china"
    {
        $oauth2Permissions = @(@{
            adminConsentDescription = "Allow the application to access " + $WebApplicationName + " on behalf of the signed-in user."
            adminConsentDisplayName = "Access " + $WebApplicationName
            id = [guid]::NewGuid()
            isEnabled = $true
            type = "User"
            userConsentDescription = "Allow the application to access " + $WebApplicationName + " on your behalf."
            userConsentDisplayName = "Access " + $WebApplicationName
            value = "user_impersonation"
        })
        $webApp.oauth2Permissions = $oauth2Permissions
    }
}

$webApp = CallGraphAPI $uri $headers $webApp
AssertNotNull $webApp 'Web Application Creation Failed'
$ConfigObj.WebAppId = $webApp.appId
Write-Host 'Web Application Created:' $webApp.appId

#Service Principal
$uri = [string]::Format($graphAPIFormat, "servicePrincipals")
$servicePrincipal = @{
    accountEnabled = "true"
    appId = $webApp.appId
    displayName = $webApp.displayName
    appRoleAssignmentRequired = "true"
}
$servicePrincipal = CallGraphAPI $uri $headers $servicePrincipal
$ConfigObj.ServicePrincipalId = $servicePrincipal.objectId

#Create Native Client Application
$uri = [string]::Format($graphAPIFormat, "applications")
$nativeAppResourceAccess = $requiredResourceAccess +=
@{
    resourceAppId = $webApp.appId
    resourceAccess = @(@{
        id = $webApp.oauth2Permissions[0].id
        type= "Scope"
    })
}
$nativeApp = @{
    publicClient = "true"
    displayName = $NativeClientApplicationName
    replyUrls = @("urn:ietf:wg:oauth:2.0:oob")
    requiredResourceAccess = $nativeAppResourceAccess
}
$nativeApp = CallGraphAPI $uri $headers $nativeApp
AssertNotNull $nativeApp 'Native Client Application Creation Failed'
Write-Host 'Native Client Application Created:' $nativeApp.appId
$ConfigObj.NativeClientAppId = $nativeApp.appId

#Service Principal
$uri = [string]::Format($graphAPIFormat, "servicePrincipals")
$servicePrincipal = @{
    accountEnabled = "true"
    appId = $nativeApp.appId
    displayName = $nativeApp.displayName
}
$servicePrincipal = CallGraphAPI $uri $headers $servicePrincipal

#OAuth2PermissionGrant

#AAD service principal
$uri = [string]::Format($graphAPIFormat, "servicePrincipals") + '&$filter=appId eq ''00000002-0000-0000-c000-000000000000'''
$AADServicePrincipalId = (Invoke-RestMethod $uri -Headers $headers).value.objectId

$uri = [string]::Format($graphAPIFormat, "oauth2PermissionGrants")
$oauth2PermissionGrants = @{
    clientId = $servicePrincipal.objectId
    consentType = "AllPrincipals"
    resourceId = $AADServicePrincipalId
    scope = "User.Read"
    startTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffff")
    expiryTime = (Get-Date).AddYears(1800).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffff")
}
CallGraphAPI $uri $headers $oauth2PermissionGrants | Out-Null
$oauth2PermissionGrants = @{
    clientId = $servicePrincipal.objectId
    consentType = "AllPrincipals"
    resourceId = $ConfigObj.ServicePrincipalId
    scope = "user_impersonation"
    startTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffff")
    expiryTime = (Get-Date).AddYears(1800).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffff")
}
CallGraphAPI $uri $headers $oauth2PermissionGrants | Out-Null

$ConfigObj

#ARM template
Write-Host
Write-Host '-----ARM template-----'
Write-Host '"azureActiveDirectory": {'
Write-Host ("  `"tenantId`":`"{0}`"," -f $ConfigObj.TenantId)
Write-Host ("  `"clusterApplication`":`"{0}`"," -f $ConfigObj.WebAppId)
Write-Host ("  `"clientApplication`":`"{0}`"" -f $ConfigObj.NativeClientAppId)
Write-Host "},"

