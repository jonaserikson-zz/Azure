
#List all locations and select one
$location = (Get-AzureRmLocation).location | Out-GridView -Title "Select Azure location" -PassThru

#List all publishers and select one
$publisher = Get-AzureRmVMImagePublisher -Location $location | Select -ExpandProperty PublisherName | Out-GridView -Title "Select Publisher" -PassThru

#Get all offers for selected publisher
$Alloffers = @(Get-AzureRmVMImageOffer -Location $location -Publisher $publisher | Select -ExpandProperty Offer)

#Get all images for all skus of all ofers for the selected publisher
foreach ($Offer in $Alloffers) {
$Allskus = (Get-AzureRmVMImageSku -Location $location -Publisher $publisher -Offer $offer | Select  -ExpandProperty Skus)
 foreach ($sku in $Allskus) {s
$Allimages += @(Get-AzureRmVMImage -Location $location -PublisherName $publisher -Offer $offer -Skus $sku)
 }
 }

#Wash and sort object
$Allversions = $Allimages | select Version,Skus,Offer,PublisherName | Sort-Object Skus
Write-Output $Allversions
#$Allversions | Export-Csv c:\temp\All-Images-Skus-Offer.csv
