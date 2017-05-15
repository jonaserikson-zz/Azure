(Get-AzureRmLog -ResourceId /subscriptions/42c39cb1-d162-4ac1-898a-4c527789e055/resourceGroups/testblobbenrg/providers/Microsoft.Storage/storageAccounts/testblobben29).caller
(Get-AzureRmResourceGroupDeploymentOperation -ResourceGroupName testblobbenrg -DeploymentName Microsoft.StorageAccount-20170514143315).id





$sku = Get-AzureADSubscribedSku | Select-Object SkuPartNumber, {$_.prepaidunits.enabled}, consumedunits
