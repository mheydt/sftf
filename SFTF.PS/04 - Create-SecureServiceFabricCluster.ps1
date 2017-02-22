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

# Set the Subscription ID; needed if you have more than one - and you need to change to yours
$subscriptionId = "b02264bc-1ea4-4849-abb9-60b5293ed558" 

# Replace with your key vaults resource id
$keyVaultResourceId = "/subscriptions/b02264bc-1ea4-4849-abb9-60b5293ed558/resourceGroups/sfhackRG/providers/Microsoft.KeyVault/vaults/sfhackKV"

# Replace with your key vault secret's id, which was obtained as output of adding the secret to key vault
$keyVaultSecretId = "https://sfhackkv.vault.azure.net:443/secrets/mySecretName/2425d932d9bb442e8bdedba4b2ce8bc1"

# Replace with the thumbprint of your certificate.  This is for mysfcluster1.pfx
$certificateThumbprint = "812508463AE35AF784956315D3414DF1854CF8A6"

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

# Paths of the template and parameter files
$templateFilePath = "$PSScriptRoot/templates/cluster1_template.json"
$parametersFilePath = "$PSScriptRoot/templates/cluster1_parameters.json"

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

# log into azure
Login-AzureRmAccount

# If more than one under your account, you need to specify the specific subscription id
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# this will validate the configuration
$validation = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
                                                  -TemplateFile $templateFilePath `
												  -TemplateParameterObject $parameters 

if ($validation.Count -eq 0)
{
	# validation passed, deploy the cluster
	New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
									   -TemplateFile $templateFilePath `
									   -TemplateParameterObject $parameters 


}
else
{
    Write-Output "Error Validating Template:" $validation
}
