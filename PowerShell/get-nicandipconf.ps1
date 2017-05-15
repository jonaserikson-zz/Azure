$objectArr = @()
$Date = Get-date -format yyyy-MM-dd
$MachineNames = (find-AzureRmResource | Where {($_.ResourceType -eq "Microsoft.Compute/virtualMachines" -or $_.ResourceType -eq "Microsoft.ClassicCompute/virtualMachines")})
#$AllManaged = (find-AzureRmResource -TagName managedservice | Where {$_.ResourceType -eq "Microsoft.Compute/virtualMachines"}).Name
foreach ($MachineName in $MachineNames) {
$Nic = (Get-AzureRmNetworkInterface | where {$_.VirtualMachine.Id -eq $MachineName.ResourceId})

    $prop = [ordered]@{
        'Name' = $MachineName.Name
        'ResourceGroup' = $MachineName.ResourceGroupName
        'PrivateIpAddress' = $Nic.IpConfigurations.PrivateIpAddress
        'AllocationMethod' = $Nic.IpConfigurations.PrivateIpAllocationMethod
        'Subnet' = $nic.IpConfigurations.Subnet.Id
        'Tags.managedservice' = ($MachineName.Tags.managedservice)
        'Tags.customercontact' = ($MachineName.Tags.customercontact)
        'Tags.technicalcontact' = ($MachineName.Tags.technicalcontact)
        'Date' = $Date
        }
 $obj = New-Object -Type PSCustomObject -Property $prop
 $objectArr += $obj

 }
 #$objectArr| Where {$_.Name -match "ied*"}
 $objectArr


$objectArr | Export-Csv c:\temp\studd.csv -NoTypeInformation
