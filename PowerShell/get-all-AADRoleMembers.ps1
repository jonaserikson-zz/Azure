$objectArr = @()
$RolesId = (Get-AzureADDirectoryRole).objectId

foreach ($RoleId in $RolesId) {
$RoleType = (Get-AzureADDirectoryRole -ObjectId $RoleId).DisplayName
$RoleMembers = Get-AzureADDirectoryRoleMember -ObjectId $RoleId
$UserMembers = ($RoleMembers | where {$_.ObjectType -eq "User"}).objectID

foreach ($UserMember in $UserMembers) {
$UPN = (Get-AzureADUser -ObjectId $UserMember).UserPrincipalName

    $prop = [ordered]@{
        'User' = $UPN
        'Group' = $RoleType
        }
 $obj = New-Object -Type PSCustomObject -Property $prop
 $objectArr += $obj
}
 }
 $objectArr
