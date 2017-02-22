#
# 01 - Create_SelfSignedCert.ps1
#
# This script creates a self-signed certificate 
#
# Note that this script does not work on windows 7, or < powershell 5
# 

# DNS name for the certificate
# If you are using this for service fabric, this must match the name of the service fabric cluster
# that your are attempting to authenticate with
$certDNSName = "mysfcluster1"

# This will be the name of the certificate file
$certFileName = $certDNSName

# Change this to where you would like to store the certificate file
$certFileFullPath = "$PSScriptRoot/certs/$certFileName.pfx"

# Must specify a password for the certificate
$password = "TheCertsPassword!1234"

# Need to create a secure password object
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

#Creates a new selfsigned cert and exports a pfx cert to a directory on disk
$newCert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -DnsName $certDNSName 
Export-PfxCertificate -FilePath $certFileFullPath -Password $securePassword -Cert $newCert

# Later examples will require this certificate being in the local certificate store, so put it there
Import-PfxCertificate -FilePath $certFileFullPath -Password $securePassword -CertStoreLocation Cert:\LocalMachine\My 

Write-Host "Created a certificate at $certFileFullPath"
Write-Host "Thumbprint: $newCert.Thumbprint"