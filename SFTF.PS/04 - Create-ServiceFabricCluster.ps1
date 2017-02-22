#
# Create_ServiceFabricCluster.ps1
#
# Creates a secure service fabric cluster in a preexisting resource group and region
# Key vault must already exist
#
# Remember to change the values for $certificateThumbprint, $keyVaultResourceId, and $keyVaultSecretId
# along with your specific $clusterName, $location, $resourceGroupName
#

# The name of your Service Fabric cluster
$clusterName = "mysfcluster1"

# Which region of azure?
$location = "westus"

# The resource group where you want to place the cluster
$resourceGroupName = "sfhackRG"

# Paths of the template and parameter files
$templateFilePath = "$PSScriptRoot/templates/cluster1_template.json"
$parametersFilePath = "$PSScriptRoot/templates/cluster1_parameters.json"

# Replace with the thumbprint of your certificate.  This is for mysfcluster1.pfx
$certificateThumbprint = "C7F88BBF8DD2FA3BB461F11B3F6C8C7B67BA1FE0"

# Replace with your key vaults resource id
$keyVaultResourceId = "/subscriptions/b02264bc-1ea4-4849-abb9-60b5293ed558/resourceGroups/sfhackRG/providers/Microsoft.KeyVault/vaults/sfhackKV"

# Replace with your key vault secret's id
$keyVaultSecretId = "https://sfhackkv.vault.azure.net:443/secrets/mySecretName/8ac151d8b431444ca2fed1e06564ca52"

# mysfcluster2.pfx
# $certificateThumbprint = "015B7EA8023C0DEB2FE21280AE6F6425D0B557DC"
# mysfcluster3.pfx
# $certificateThumbprint = "3789E0A881409BC5283C326BE980F23D84FE9104"
# mysfcluster4.pfx
# $certificateThumbprint = "C6C89C4D8F01CA174233734568828E84BAF56499"
# mysfcluster5.pfx
# $certificateThumbprint = "279B5F1101838B70825B0885FEC503064159C862"
# mysfcluster6.pfx
# $certificateThumbprint = "5BF3305C59F5BB830A92C4D7F5BDC97C70A845B2"

# Read the Json Parameters file and Convert to HashTable
$parameters = New-Object -TypeName hashtable 
$jsonContent = Get-Content $parametersFilePath  -Raw | ConvertFrom-Json 
$jsonContent.parameters.psobject.Properties.Name `
        | ForEach-Object {$parameters.Add($_ ,$jsonContent.parameters.$_.Value)}

# Complete Parameters Values, substituting defaults with the values you specified earlier
# You can overwrite more if you want to
$parameters["clusterLocation"] = $location
$parameters["certificateThumbprint"] = $certificateThumbprint   
$parameters["sourceVaultValue"] = $keyVaultResourceId
$parameters["certificateUrlValue"] = $keyVaultSecretId
$parameters["dnsName"] = $clusterName
$parameters["clusterName"] = $clusterName

# this will validate the configuration
$validation = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
                                                  -TemplateFile $templateFilePath `
												  -TemplateParameterObject $parameters 

if ($validation.Count -eq 0)
{
	# validation passed
	New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
									   -TemplateFile $templateFilePath `
									   -TemplateParameterObject $parameters 


}
else
{
    Write-Output "Error Validating Template:" $validation
}
