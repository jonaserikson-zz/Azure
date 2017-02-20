$AllSubs = @(Get-AzureRmSubscription | Select -ExpandProperty SubscriptionName)
foreach ($SubName in $AllSubs) {
Select-AzureRmSubscription -SubscriptionName $SubName
$ResourceFilter += (find-AzureRmResource | Where {($_.ResourceType -eq "Microsoft.Compute/virtualMachines" -or $_.ResourceType -eq "Microsoft.ClassicCompute/virtualMachines")})
 }
