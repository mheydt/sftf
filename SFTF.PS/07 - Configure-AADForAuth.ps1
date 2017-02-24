# name of your service fabric cluster - change as needed
$clusterName = "mikeheydtsf"

# names for the two applications that will be created in AAD - change as needed
$webApplicationName = "ServiceFabricCluster Explorer UI"
$nativeClientApplicationName = "ServiceFabricCluster Native App"

# this is the return URI for the SF explorer - needed for OAuth
$webApplicationReplyUrl = "https://" + $clusterName + ".westus.cloudapp.azure.com:19080/Explorer/index.html"
$webApplicationUri = $webApplicationReplyUrl

# This is the tenant id / url for your AAD directory where the apps will be created - change as needed
$tenantID = "sfhackathon.onmicrosoft.com"

# needed for using the GraphAPI 
$authString = "https://login.microsoftonline.com/$tenantID"
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
$nativeAppRedirectUrl = "urn:ietf:wg:oauth:2.0:oob"
$resourceUrl = "https://graph.windows.net"

# these various URLs are used for calling the graph api
$graphAPIFormat = $resourceUrl + "/" + $tenantId + "/{0}?api-version=1.5"
$applicationsUri = [string]::Format($graphAPIFormat, "applications")
$userUri = [string]::Format($graphAPIFormat, "users")
$principalsUri = [string]::Format($graphAPIFormat, "servicePrincipals")
$oauthPermissionsGrantUri = [string]::Format($graphAPIFormat, "oauth2PermissionGrants")
$aadPrincipalUri = $principalsUri + '&$filter=appId eq ''00000002-0000-0000-c000-000000000000'''

# defines two roles for users for the web applications: ReadOnly and Admin
$appRoles = 
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

$oauth2Permissions = @(@{
    adminConsentDescription = "Allow the application to access " + $webApplicationName + " on behalf of the signed-in user."
    adminConsentDisplayName = "Access " + $webApplicationName
    id = [guid]::NewGuid()
    isEnabled = $true
    type = "User"
    userConsentDescription = "Allow the application to access " + $webApplicationName + " on your behalf."
    userConsentDisplayName = "Access " + $webApplicationName
    value = "user_impersonation"
})

# need to reference these two assemblies
$FilePath = Join-Path $PSScriptRoot "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
Add-Type -Path $FilePath
$FilePath = Join-Path $PSScriptRoot "Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
Add-Type -Path $FilePath

# calls a rest API
function CallGraphAPI($uri, $headers, $body)
{
    $json = $body | ConvertTo-Json -Depth 4 -Compress
    return (Invoke-RestMethod $uri -Method Post -Headers $headers -Body $json -ContentType "application/json")
}

# creates a user in AAD using GraphAPI
function CreateUser($uri, $headers, $tenantID, $username, $password, $displayName, $mailKnickName)
{
	$body = @{
		accountEnabled = "true"
		displayName = $displayName
		mailNickName = $mailKnickName
		passwordProfile = @{
			password = $password
			forceChangePasswordNextLogin = "false"
		}
		userPrincipalName = $username + "@" + $tenantID
	}
	$user = CallGraphAPI $uri $headers $body
	$user
}

# creates an application in AAD, and also its associated security principal
function CreateApplication($applicationsURI, $principalsURI, $headers, `
	                       $displayName, `
						   $identifierURL, $homepage, $replyURLs, `
						   $appRoles, $oauth2Permissions, `
						   $requiredResources, $publicClient)
{
	# Create AAD application
	$appData = @{
		displayName = $displayName
		replyUrls = @($replyURLs)
	}
	if ($appRoles)
	{
		#$appData.appRoleAssignmentRequired = "true"
		$appData.appRoles = $appRoles
	}
	if ($identifierURL)
	{
		$appData.identifierUris = @($identifierURL)
	}
	if ($homepage)
	{
		$appData.homePage = $homepage
	}
	if ($requiredResources)
	{
		$appData.requiredResourceAccess = $requiredResources
	}
	if ($publicClient)
	{
		$appData.publicClient = $publicClient
	}
	if ($oauthPermissions)
	{
		$appData.oauth2Permissions = $oauth2Permissions
	}
	$app = CallGraphAPI $applicationsURI $headers $appData

	$servicePrincipalData = @{
		accountEnabled = "true"
		appId = $app.appId
		displayName = $app.displayName
	}
	if ($appRoles)
	{
		$servicePrincipalData.appRoleAssignmentRequired = "true"
	}

	$servicePrincipal = CallGraphAPI $principalsURI $headers $servicePrincipalData

	Return $app, $servicePrincipal
}

# sets oauth grants in AAD
function CreateOAuthPermissionGrants($oauthURL, $headers, $clientID, $resourceId, $scope)
{
	$oauth2PermissionGrants = @{
		clientId =$clientID
		consentType = "AllPrincipals"
		resourceId = $resourceId
		scope = $scope
		startTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffff")
		expiryTime = (Get-Date).AddYears(1800).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffff")
	}
	CallGraphAPI $oauthPermissionsGrantUri $headers $oauth2PermissionGrants 
	$oauth2PermissionGrants
}

# first thing we need to do is get the authorization token which allows us to access AAD via GraphAPI
$authenticationContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext -ArgumentList $authString, $FALSE
$accessToken = $authenticationContext.AcquireToken($resourceUrl, $clientId, $redirectUrl, [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::RefreshSession).AccessToken

# put the token in the headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $accessToken)

# create the web application in AAD
$webApp, $webAppPrincipal = CreateApplication $applicationsUri $principalsUri $headers `
											  $webApplicationName `
											  $webApplicationUri $webApplicationReplyUrl $webApplicationReplyUrl `
											  $appRoles $oauth2Permissions `
											  $null $null
Write-Host 'Cluster application created: ' $webApp.appId

# Create Native Client Application AAD
$requiredResourceAccess =
@(@{
	# this is the service principal for AAD itself
    resourceAppId = "00000002-0000-0000-c000-000000000000"
    resourceAccess = @(@{
		# this is "sign in and read user profile"
        id = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
        type= "Scope"
    })
})

$nativeAppResourceAccess = $requiredResourceAccess +=
@{
    resourceAppId = $webApp.appId
    resourceAccess = @(@{
        id = $webApp.oauth2Permissions[0].id
        type= "Scope"
    })
}

$nativeApp, $nativeAppPrincipal = CreateApplication $applicationsUri $principalsUri $headers `
													$nativeClientApplicationName `
													$null $null $nativeAppRedirectUrl `
													$null $null `
													$nativeAppResourceAccess "true"
Write-Host 'Client application created: ' $nativeApp.appId
Write-Host $nativeApp.appRoles

# Get the AAD service principal; we need this for performing OAuth grants
$aadServicePrincipal = (Invoke-RestMethod $aadPrincipalUri -Headers $headers)

# Tell AAD which OAuth grants should be used in each application
$grants1 = CreateOAuthPermissionGrants $oauthPermissionsGrantUri $headers $nativeAppPrincipal.objectId $aadServicePrincipal.value.objectId "User.Read"
$grants2 = CreateOAuthPermissionGrants $oauthPermissionsGrantUri $headers $nativeAppPrincipal.objectId $webAppPrincipal.objectId "user_impersonation"

# now create two users
$clusterReader = CreateUser $userUri $headers $tenantID "cluster_reader" "Foo!1234" "Cluster Reader" "CR"
$clusterAdmin = CreateUser $userUri $headers $tenantID "cluster_admin" "Bar!1234" "Cluster Admin" "CA"
