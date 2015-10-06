# Azure
Add-AzureAccount
$subscriptionId =
    (Get-AzureSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId
        $adTenant =
    (Get-AzureSubscription `
        -SubscriptionId $subscriptionId).TenantId

# REST API
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2" # Well-known client ID for Azure PowerShell
$redirectUri = "urn:ietf:wg:oauth:2.0:oob" # Redirect URI for Azure PowerShell
$resourceAppIdURI = "https://management.core.windows.net/" # Resource URI for REST API
$authority = "https://login.windows.net/$adTenant" # Azure AD Tenant Authority


# Create Authentication Context tied to Azure AD Tenant
$authContext = New-Object -TypeName "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext"  -ArgumentList $authority

# Acquire Azure AD token
$authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")

# Create Authorization Header
$authHeader = $authResult.CreateAuthorizationHeader()
# Set HTTP request headers to include Authorization header
$requestHeader = @{"Authorization" = $authHeader}

# Set REST API parameters
$apiVersion = "2015-06-01-preview"
$contentType = "application/json;charset=utf-8"

$offerDurableID = "MS-AZR-0003p"
$currency = "SEK"
$locale = "se-se"
$region = "SE"
$rateCardUri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Commerce/RateCard?api-version=$apiVersion`&`$filter=OfferDurableId eq '$offerDurableID' and Currency eq '$currency' and Locale eq '$locale' and RegionInfo eq '$region'"
Invoke-RestMethod -Uri $rateCardUri -Method Get -Headers $requestHeader -ContentType $contentType -OutFile rateCard.json
