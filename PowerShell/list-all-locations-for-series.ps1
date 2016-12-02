
$Series = "Standard_N*"
$locations = (Get-AzureRmLocation).location
foreach ($location in $locations) {
$Sizes = (Get-AzureRmVMSize -Location $location | Where {$_.Name -like $Series}).Name
Write-output $location
write-output ..............
write-output $Sizes
write-output ""
write-output ""
 }
