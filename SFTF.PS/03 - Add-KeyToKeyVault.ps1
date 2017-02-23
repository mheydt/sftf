#
# 03 - Add_KeyToKeyVault.ps1
#
# Adds a certificate to a key vault as a secret
#
#

# The certificate that you want to add
# Note that if you are going to use this as authentication to a Service Fabric cluster,
# the DNS in the certificate must match the name of that cluster's FQDN
$certFileFullPath = "$PSScriptRoot/certs/mikeheydtsf.pfx"

# Must specify a password for the certificate, same as when it was created
$password = "TheCertsPassword!1234"

# Need to create a secure password object
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

# Used for the naming of hte key vault
$keyVaultName = "sfhackKV"

# Specify the name of the "secret" we are putting in Key Vault
$keyVaultSecretName = "mySecretName"

# Set the Subscription ID; needed if you have more than one - and you need to change to yours
$subscriptionId = "15b8ace7-90d7-4555-820a-acefe105886b" 

# thumbprint for the cluster cert
$certificateThumbprint = "DBA6805A125CBA9C3F090D457B2B51DFD57CCE84"

# Login to Azure
Login-AzureRmAccount

# If more than one under your account, you need to specify the specific subscription id
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# read the certificate in and convert it to base64
$base64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($certFileFullPath))

# We need to create a JSON blob object with these values
$jsonBlob = @{
    data = $base64
    dataType = 'pfx'
    password = $password
} | ConvertTo-Json

# Convert the blob to base64
$content = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($jsonBlob))

# Now convert the json content a secure string
$secretValue = ConvertTo-SecureString -String $content -AsPlainText -Force

#Creates a new secret in Azure Key Vault
$newSecret = Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name $keyVaultSecretName -SecretValue $secretValue -Verbose

# If you use this to create a secure Service Fabric cluster, you will need this info
Write-Host "Resource Id: "$(Get-AzureRmKeyVault -VaultName $keyVaultName).ResourceId
Write-Host "Secret URL : "$newSecret.Id
Write-Host "Thumbprint : "$newCert.Thumbprint