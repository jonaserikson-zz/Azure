$resourceProvider = Get-AzureRmResourceProvider -ListAvailable | ? {$_.RegistrationState -eq "NotRegistered"} | select ProviderNamespace | Out-GridView -Title "Select Provider Namespace" -PassThru
Register-AzureRmResourceProvider -ProviderNamespace $resourceProvider.ProviderNamespace
