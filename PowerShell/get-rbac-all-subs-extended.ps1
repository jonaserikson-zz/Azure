$objectArr = @()
$AllSubs = @(Get-AzureRmSubscription)

foreach ($SubName in $AllSubs.SubscriptionName) {
$SubID = (Get-AzureRmSubscription -SubscriptionName $SubName).SubscriptionId

Select-AzureRmSubscription -SubscriptionName $SubName
$AllRoleAss = (Get-AzureRmRoleAssignment -IncludeClassicAdministrators)

foreach ($RoleAss in $AllRoleASs) {
     $prop = [ordered]@{
         'SubscriptionName' = $SubName
         'SubscriptionID' = $SubID
         'DisplayName' = $roleAss.DisplayName
         'SignInName' = $roleAss.SignInName
         'RoleDefinitionName' = $roleAss.RoleDefinitionName
         'ObjectType' = $roleAss.ObjectType
         'Scope' = $RoleAss.Scope

         }
  $obj = New-Object -Type PSCustomObject -Property $prop
  $objectArr += $obj
 }
  }
  $objectArr
#$objectArr | Export-Csv c:\temp\AllRBAC.csv -NoTypeInformation
