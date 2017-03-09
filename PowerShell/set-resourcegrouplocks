$ResourceGroups = Find-AzureRmResourceGroup.Name
$LockLevel = "CanNotDelete"
$LockNotes = "A ResourceLock automatically set by schedule"
foreach ($ResourceGroup in $ResourceGroups) {
New-AzureRmResourceLock -LockLevel $LockLevel -LockName ($ResourceGroup + "_" + $LockLevel) -LockNotes $LockNotes -ResourceGroupName $ResourceGroup -Force
 }
