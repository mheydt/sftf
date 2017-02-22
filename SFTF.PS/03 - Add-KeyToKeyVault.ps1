#
# Add_KeyToKeyVault.ps1
#
# Adds a certificate to a key vault as a secret
#
#

# The certificate that you want to add
# Note that if you are going to use this as authentication to a Service Fabric cluster,
# the DNS in the certificate must match the name of that cluster's FQDN
$certFileFullPath = "$PSScriptRoot/certs/mysfcluster1.pfx"

# Must specify a password for the certificate, same as when it was created
$password = "TheCertsPassword!1234"

# Need to create a secure password object
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

# Specify the name of the "secret" we are putting in Key Vault
$keyVaultSecretName = "mySecretName"

# Login to Azure
Login-AzureRmAccount

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
Write-Host
Write-Host "Resource Id: "$(Get-AzureRmKeyVault -VaultName $keyVaultName).ResourceId
Write-Host "Secret URL : "$newSecret.Id
Write-Host "Thumbprint : "$newCert.Thumbprint