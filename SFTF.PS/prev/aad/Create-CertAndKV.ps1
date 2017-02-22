#
# CreateCertAndKV.ps1
#
#-----You have to change the variable values-------#
# This script will:
#  1. Create a new resource group for your key vaults
#  2. Create a new key vault
#  3. Create, export and import (to your certificate store) a self-signed certificate
#  4. Create a new secret and put the cert in key vault
#  5. Output the values you will need to supply to your cluster for cluster cert security.
#     Make sure you copy these values before closing the PowerShell window
#--------------------------------------------------#

#Name of the Key Vault service
$KeyVaultName = "sfhackkv" 
#Resource group for the Key-Vault service. 
$ResourceGroup = "sfhack"
#Set the Subscription
$subscriptionId = "b02264bc-1ea4-4849-abb9-60b5293ed558" 
#Azure data center locations (East US", "West US" etc)
$Location = "West US"
#Password for the certificate
$Password = "ThePassword!1234"
#DNS name for the certificate
$CertDNSName = "sbuxspc"
#Name of the secret in key vault
$KeyVaultSecretName = "ServiceFabricSecret"
#Path to directory on local disk in which the certificate is stored  
$CertFileFullPath = "C:\Dev\sftf\SFTF.PS\$CertDNSName.pfx"

Login-AzureRmAccount

#If more than one under your account
Select-AzureRmSubscription -SubscriptionId $subscriptionId
#Verify Current Subscription
Get-AzureRmSubscription -SubscriptionId $subscriptionId


#Creates the a new resource group and Key-Vault
New-AzureRmResourceGroup -Name $ResourceGroup -Location $Location
New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -Location $Location -sku standard -EnabledForDeployment 

#Converts the plain text password into a secure string
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

#Creates a new selfsigned cert and exports a pfx cert to a directory on disk
$NewCert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -DnsName $CertDNSName 
Export-PfxCertificate -FilePath $CertFileFullPath -Password $SecurePassword -Cert $NewCert
Import-PfxCertificate -FilePath $CertFileFullPath -Password $SecurePassword -CertStoreLocation Cert:\LocalMachine\My 

#Reads the content of the certificate and converts it into a json format
$Bytes = [System.IO.File]::ReadAllBytes($CertFileFullPath)
$Base64 = [System.Convert]::ToBase64String($Bytes)

$JSONBlob = @{
    data = $Base64
    dataType = 'pfx'
    password = $Password
} | ConvertTo-Json

$ContentBytes = [System.Text.Encoding]::UTF8.GetBytes($JSONBlob)
$Content = [System.Convert]::ToBase64String($ContentBytes)

#Converts the json content a secure string
$SecretValue = ConvertTo-SecureString -String $Content -AsPlainText -Force

#Creates a new secret in Azure Key Vault
$NewSecret = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretName -SecretValue $SecretValue -Verbose

#Writes out the information you need for creating a secure cluster
Write-Host
Write-Host "Resource Id: "$(Get-AzureRmKeyVault -VaultName $KeyVaultName).ResourceId
Write-Host "Secret URL : "$NewSecret.Id
Write-Host "Thumbprint : "$NewCert.Thumbprint

