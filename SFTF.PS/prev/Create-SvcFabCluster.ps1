function SetupCertificates()
{
 
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
    $clusterCertificates = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 $certificateFilePath, $certificatePassword
    $clusterCertificates
}

function GetOrCreateKeyVault
{
    if (-not (Get-AzureRmResourceGroup | ? ResourceGroupName -eq $resourceGroupName))
    {
        $newResourceGroup = New-AzureRmResourceGroup  -Name $ResourceGroupName -Location $Location -Verbose 
    }
    
    if( -not (Get-AzureRmKeyVault -ResourceGroupName $ResourceGroupName | ? VaultName -eq $VaultName ))
    {
        Write-Host "Creating vault $VaultName in $location (resource group $ResourceGroupName)"    
        $keyVault = New-AzureRmKeyVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName -Location $Location `
                                        -EnabledForDeployment -Verbose  -Sku premium   
    }
    else 
    {
        $keyVault = Get-AzureRmKeyVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName  
    }        
    
    $keyVault

}

function AddCertificateToKeyVault
{
  Param(
      [string] $SecretName,  
      [string] $PfxFilePath,
      [System.Security.SecureString] $Password,
      [string] $ResourceGroupName,  
      [string] $Location,  
      [string] $VaultName
     )
     $ErrorActionPreference = 'Stop'       
    
    if( -not (Get-AzureKeyVaultSecret   -VaultName $VaultName | ? Name -eq $secretName))
    {
        $bytes = [System.IO.File]::ReadAllBytes($PfxFilePath)
        $base64 = [System.Convert]::ToBase64String($bytes)

        $jsonBlob = @{
            data = $base64
            dataType = 'pfx'
            password = $clearPassword
        } | ConvertTo-Json

        $contentbytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBlob)
        $content = [System.Convert]::ToBase64String($contentbytes)

        $secretValue = ConvertTo-SecureString -String $content -AsPlainText -Force
     
        Write-Host "Writing secret $SecretName to vault $VaultName"
        $keyVaultSecret = Set-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $secretValue -Verbose         
     }
     else
     {
		$keyVaultSecret = Get-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName
     }

    $keyVaultSecret
 }

function SetClusterTemplateParameters()
{
    
    # Read the Json Parameters file and Convert to HashTable
    $parameters = New-Object -TypeName hashtable 
    $jsonContent = Get-Content $parametersFileLocation  -Raw | ConvertFrom-Json 
    $jsonContent.parameters.psobject.Properties.Name `
            | ForEach-Object {$parameters.Add($_ ,$jsonContent.parameters.$_.Value)}
    
    # Complete Parameters Values 
    $parameters["clusterLocation"] = $location
    $parameters["adminPassword"] = $clearPassword
    $parameters["certificateThumbprint"] = $clusterCertificate.Thumbprint   
    $parameters["sourceVaultValue"] = $keyVault.ResourceId
    $parameters["certificateUrlValue"] = $keyVaultSecret.Id
    $parameters["dnsName"] = $dnsName
    $parameters["vmStorageAccountName"] = $dnsName+"stg"
    $parameters["clusterName"] = $dnsName

    $parameters
}

function ValidateClusterConnection()
{
    Start-Sleep -Seconds 120    

    $connectionEndpoint = "$dnsName.$location.cloudapp.azure.com:19000"
    Connect-serviceFabricCluster -ConnectionEndpoint $connectionEndpoint -KeepAliveIntervalInSec 10 `
		-X509Credential `
		-ServerCertThumbprint $clusterCertificate.Thumbprint  `
		-FindType FindByThumbprint `
		-FindValue $clusterCertificate.Thumbprint  `
		-StoreLocation CurrentUser `
		-StoreName My

    ##### Get cluster health and other checks    
    Get-ServiceFabricNode | Format-Table -AutoSize
    Get-ServiceFabricService fabric:/System | Format-Table -AutoSize

    ##### Print Connection details
    Write-Output "Connection Endpoint : $connectionEndpoint"
    Write-Output "Certificate Thumbprint : $clusterParameters.certificateThumbprint"
    Write-Output "Common Name : $dnsName"
}

clear

##### Parameters - ResourceGroup & KeyVault
$instanceNumber = (Get-Date -format ddMMyy) + "01"

#azure region
$location = 'westus'

# location of where you want cert files placed
$currentLocation = "c:\dev\SFTF\SFTF.PS"
$yourResourceGroup = "sfhackrg"

$dnsName = "sfhack2" # $yourName # + $instanceNumber
$resourceGroupName = $yourResourceGroup # + $instanceNumber
$deploymentName = "svcfabcluster-Initial"

##### Parameters - Certificates & Security
$certificateFilePath = "$currentLocation\$dnsName.pfx"
$cerCertificateFilePath = "$currentLocation\$dnsName.cer"
$vaultName = "sfhackvault" #$instanceNumber"
$secretName = 'ServiceFabricCert'

##### Templates Location 
$templateFileLocation = "$currentLocation\azuredeploy.json"
$parametersFileLocation = "$currentLocation\azuredeploy-parameters.json"

##### Certifate password
$certificatePassword = ConvertTo-SecureString -String "ThePassword!1234" -Force -AsPlainText

if ($certificatePassword -eq $null) {
    $certificatePassword = Read-Host -Prompt "Enter password" -AsSecureString 
}
$clearPassword = (New-Object System.Management.Automation.PSCredential 'N/A', $certificatePassword).GetNetworkCredential().Password    

######## Create And Setup Certificates
$clusterCertificate = SetupCertificates
Write-Host $clusterCertificate[2].Thumbprint
Login-AzureRmAccount
#Add-AzureRmAccount

######## Create ResourceGroup & KeyVault #####################
$keyVault = GetOrCreateKeyVault
Write-Host $keyVault.ResourceId

######## Upload the Certificates to Key Vault #####################
$keyVaultSecret = AddCertificateToKeyVault -ResourceGroupName $resourceGroupName -Location $location -VaultName $vaultName -SecretName $secretName -PfxFilePath $certificateFilePath -Password $certificatePassword
Write-Host $keyVaultSecret.Id

####### Retrieve and Print Cluster Parameters #####################
$clusterParameters = SetClusterTemplateParameters
Write-Host $clusterParameters

####### Create Service Fabric Cluster #####################
$validation = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
                                                  -TemplateFile $templateFileLocation -TemplateParameterObject $clusterParameters 

if($validation.Count -eq 0)
{
        New-AzureRmResourceGroupDeployment  -Name $deploymentName -ResourceGroupName $resourceGroupName `
                                            -TemplateFile  $templateFileLocation  -TemplateParameterObject $clusterParameters       
        
        ####### STEP 6 : Validate Connection to Cluster #####################
        ValidateClusterConnection  

}
else
{
    Write-Output "Error Validating Template:" $validation
}
