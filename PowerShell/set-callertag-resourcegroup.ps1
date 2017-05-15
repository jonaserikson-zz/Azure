$NullResourceGroupCreators = Find-AzureRmResourceGroup | Where {$_.Tags.Creator -eq $null}
foreach ($NullResourceGroupCreator in $NullResourceGroupCreators) {
$ResourceGroupWrite = (Get-AzureRmLog -ResourceGroup $NullResourceGroupCreator.Name | Where {($_.OperationName -eq "Microsoft.Resources/subscriptions/resourcegroups/write" -and $_.SubStatus -eq "Created")}) | Select-Object -Last 1
$ResourceGroupCreator = $ResourceGroupWrite.caller
if ($ResourceGroupCreator -ne $null) {
Set-AzureRmResourceGroup -Name $NullResourceGroupCreator.Name -Tag @{Creator="$ResourceGroupCreator"}
            }
}
