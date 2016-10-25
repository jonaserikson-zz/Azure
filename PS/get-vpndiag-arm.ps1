
# STEP 1 – SIGN IN TO BOTH Azure SM and RM
$cred = Get-Credential
Add-AzureRmAccount -Credential $cred
$SubscriptionName = (Get-AzureRmSubscription).SubscriptionName | Out-GridView -Title "Select Azure Subscription" -PassThru
$SubscriptionID = (Get-AzureRmSubscription -SubscriptionName $SubscriptionName).SubscriptionId
# Sign-in to Azure via Azure Resource Manager and also Sign into Azure Service Manager
# Set up Azure Resource Manager Connection
Select-AzureRmSubscription -SubscriptionId $subscriptionId
 
 
# Set up Service Manager Connection – Required as gateway diagnostics are still running on Service Manager and not ARM as yet.
Add-AzureAccount -Credential $cred
Select-AzureSubscription -SubscriptionId $subscriptionId
 
# VNET Resource Group and Name
$rgName = (Get-AzureRmResourceGroup).ResourceGroupName | Out-GridView -Title "Select RG containing Vnet" -PassThru
$vnetGws = Get-AzureRmVirtualNetworkGateway -ResourceGroupName $rgName
$vnetGwName = ($vnetGws).Name | Out-GridView -Title "Select Vnet GW" -PassThru
$timestamp = get-date -uFormat "%d%m%y@%H%M%S"
 
# Details of existing Storage Account that will be used to collect the logs
$storageAccountName = (Get-AzureRmStorageAccount).StorageAccountName | Out-GridView -Title "Select SA for debug" -PassThru
$getsarg = (Get-AzureRmStorageAccount | where {$_.StorageAccountName -match $storageaccountname}).ResourceGroupName
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $getsarg -Name $storageAccountName).Value[0]
$captureDuration = 60
$storageContainer = "vpnlogs"
$logDownloadPath = "C:\Temp"
$Logfilename = "VPNDiagLog_" + $vnetGwName + "_" + $timestamp + ".txt"
 
# Set Storage Context and VNET Gateway ID
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
 
# NOTE: This is an Azure Service Manager cmdlet and so no AzureRM on this one.  AzureRM will not work as we don’t get the gatewayID with it.
$vnetGws = Get-AzureVirtualNetworkGateway
 
# Show Details of Gateway
$vnetGws
 
# Added check for only provisioned gateways as older deleted gateways of same name can also appear in results and capture will fail
$vnetGwId = ($vnetGws | ? GatewayName -eq $vnetGwName | ? state -EQ "provisioned").GatewayID
 
# Start Azure VNET Gateway logging
Start-AzureVirtualNetworkGatewayDiagnostics  `
    -GatewayId $vnetGwId `
    -CaptureDurationInSeconds $captureDuration `
    -StorageContext $storageContext `
    -ContainerName $storageContainer
 
# Wait for diagnostics capturing to complete
Sleep -Seconds $captureDuration
 
 
# Step 6 – Download VNET gateway diagnostics log
$logUrl = ( Get-AzureVirtualNetworkGatewayDiagnostics -GatewayId $vnetGwId).DiagnosticsUrl
$logContent = (Invoke-WebRequest -Uri $logUrl).RawContent
$logContent | Out-File -FilePath $logDownloadPath\$Logfilename
notepad $logDownloadPath\$Logfilename










