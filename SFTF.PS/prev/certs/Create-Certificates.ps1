#
# Create_Certificates.ps1
#

$location = "C:\dev\sftf"
#$location = $currentLocation
$dnsName = "foo.heydt.org"
$certificateFilePath = "$location\$dnsName.pfx"
$cerCertificateFilePath = "$location\$dnsName.cer"
$certificatePassword = "myclustercert"

If (-not (Test-Path $certificateFilePath)){
    $newCer = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -DnsName $dnsName
    $newCer    | Export-PfxCertificate -FilePath $certificateFilePath -Password  $certificatePassword 

        
    $newCer | Export-Certificate -FilePath $cerCertificateFilePath -Type CERT
    ######## Set up the Certs
    #If this is a self signed cert, then add it to the Trusted People Store.Else skip.
    $importedCer = Import-PfxCertificate -Exportable -CertStoreLocation Cert:\CurrentUser\TrustedPeople -FilePath $certificateFilePath -Password $certificatePassword

    #####import the cert into your local store. this is so that you can use the cert to view the secure cluster 
    $importedCer = Import-PfxCertificate -Exportable -CertStoreLocation Cert:\CurrentUser\My -FilePath $certificateFilePath -Password $certificatePassword

}    

#$clusterCertificates = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 $certificateFilePath, $certificatePassword
#$clusterCertificates

