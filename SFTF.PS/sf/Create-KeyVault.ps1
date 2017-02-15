#
# Create_KeyVault.ps1
#

$resourceGroupName = "hackathonRG"
$location = 'westus'
$VaultName = "hackathonVault"

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