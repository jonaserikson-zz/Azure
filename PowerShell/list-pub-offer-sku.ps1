
#List all locations and select one
$location = (Get-AzureRmLocation).location | Out-GridView -Title "Select Azure location" -PassThru

#List all publishers and select one
$publisher = Get-AzureRmVMImagePublisher -Location $location | Select -ExpandProperty PublisherName | Out-GridView -Title "Select Publisher" -PassThru

#List all offers for that publisher and select one
$offer = Get-AzureRmVMImageOffer -Location $location -Publisher $publisher | Select -ExpandProperty Offer | Out-GridView -Title "Select Offer" -PassThru

#List all  skus for that Offer and select one
$sku = Get-AzureRmVMImageSku -Location $location -Publisher $publisher -Offer $offer | Select  -ExpandProperty Skus | Out-GridView -Title "Select Sku" -PassThru

#list verions for that sku
Get-AzureRmVMImage -Location $location -PublisherName $publisher -Offer $offer -Skus $sku | Out-GridView -Title "Select Versions" -PassThru