#
# Create_KeyVault.ps1
#
# This script creates a new KeyVault in the specified resource group in the specified subscription.
# Assumes resource group and keyvault do not already exist
#
# Make sure your replace with your subscription id, and desired Key Vault Name and Resource Group Name (and location)
#

# Resource group for the Key-Vault service. 
$resourceGroup = "sfhackRG" 

# Name of the Key Vault service
$keyVaultName = "sfhackKV" 

# Set the Subscription ID; needed if you have more than one - and you need to change to yours
$subscriptionId = "b02264bc-1ea4-4849-abb9-60b5293ed558" 

# Specify the region to locate the keyvault
$location = "West US"

# Login to Azure
Login-AzureRmAccount

# If more than one under your account, you need to specify the specific subscription id
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Create a new resource group
New-AzureRmResourceGroup -Name $resourceGroup -Location $location

# Now create the key vault
New-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroup -Location $location -sku standard -EnabledForDeployment 


