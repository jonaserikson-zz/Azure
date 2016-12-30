$objectArr = @()
$AllSubs = @(Get-AzureRmSubscription | Select -ExpandProperty SubscriptionName)
foreach ($SubName in $AllSubs) {
Select-AzureRmSubscription -SubscriptionName $SubName
$allResources = Get-AzureRmResource
$prop = [ordered]@{
        'SubscriptionName' = $subname
        'NumberOfResources' = ($AllResources).count
        'Date' = Get-Date -Format d
        }
 $obj = New-Object -Type PSCustomObject -Property $prop
 $objectArr += $obj
}
 $objectArr
 $objectArr | Export-Csv c:\temp\numberofresources.csv -NoTypeInformation
