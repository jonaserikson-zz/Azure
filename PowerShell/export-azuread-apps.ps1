
Get-AzureRmADApplication | select DisplayName,ObjectId, @{Name=’IdentifierUris’;Expression={[string]::join(“;”, ($_.IdentifierUris))}},HomePage,Type,ApplicationId,AvailableToOtherTenants,AppPermissions,@{Name=’ReplyUrls’;Expression={[string]::join(“;”, ($_.ReplyUrls))}} | export-csv C:\temp\adapps.csv -NoTypeInformation




$AllAppIds = (Get-AzureRmADApplication).objectid
foreach ($AppId in $AllAppIds) {
$AppOwner = (Get-AzureADApplicationOwner -ObjectId $AppId).ObjectId
$OwnerType = (Get-AzureADApplicationOwner -ObjectId $AppId).ObjectType
$Name = $null
if ($OwnerType -eq "ServicePrincipal") {
          $Name = (Get-AzureADServicePrincipal -ObjectId $AppOwner).DisplayName
            }

        elseif ($OwnerType -eq "User") {
          $Name = (Get-AzureADUser -ObjectId $AppOwner).UserPrincipalName
            }

#Write-Host $AppId , $Name

 }
