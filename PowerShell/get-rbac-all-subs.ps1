$AllSubs = @(Get-AzureRmSubscription | Select -ExpandProperty SubscriptionName)
foreach ($SubName in $AllSubs) {
Select-AzureRmSubscription -SubscriptionName $SubName
Get-AzureRmRoleAssignment -IncludeClassicAdministrators | Export-Csv c:\rbac3\subsrbac.csv -Append
 }
