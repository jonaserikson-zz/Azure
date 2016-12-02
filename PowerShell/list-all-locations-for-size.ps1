
$locations = (Get-AzureRmLocation).location
foreach ($location in $locations) {
$AllSizes += @(Get-AzureRmVMSize -Location $location).Name
 }

$AllSizes = $AllSizes | select -unique
$Size = $AllSizes | Sort-Object | Out-GridView -Title "Find all locations containing model?" -PassThru
foreach ($location in $locations) {
$Sizes = (Get-AzureRmVMSize -Location $location | Where {$_.Name -eq $Size}).Name
Write-output $location
write-output ..............
write-output $Sizes
write-output ""
write-output ""
 }
