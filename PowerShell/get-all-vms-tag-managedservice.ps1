$objectArr = @()
$AllSubs = @(Get-AzureRmSubscription | Select -ExpandProperty SubscriptionName)
foreach ($SubName in $AllSubs) {
Select-AzureRmSubscription -SubscriptionName $SubName
$AllManaged = (find-AzureRmResource | Where {$_.ResourceType -eq "Microsoft.Compute/virtualMachines"}).Name
#$AllManaged = (find-AzureRmResource -TagName managedservice | Where {$_.ResourceType -eq "Microsoft.Compute/virtualMachines"}).Name
foreach ($Managed in $AllManaged) {
$ManagedTag = (Find-AzureRmResource -ResourceNameEquals $Managed).tags.managedservice

    $prop = [ordered]@{
        'SubscriptionName' = $subname
        'Name' = $Managed
        'Tags.managedservice' = $ManagedTag
        'Date' = Get-Date -Format d
        }
 $obj = New-Object -Type PSCustomObject -Property $prop
 $objectArr += $obj

 }
 }
  $objectArr

$objectArr | Export-Csv c:\temp\managed.csv -NoTypeInformation
