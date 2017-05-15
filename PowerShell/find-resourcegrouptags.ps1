$objectArr = @()
$ResourceGroups = (find-AzureRmResourceGroup)
foreach ($ResourceGroup in $ResourceGroups) {

    $prop = [ordered]@{
        'ResourceGroup' = $ResourceGroup.Name
        'Tags.customercontact' = $ResourceGroup.Tags.customercontact
        'Tags.technicalcontact' = $ResourceGroup.Tags.technicalcontact
        'Date' = Get-Date -Format d
        }
 $obj = New-Object -Type PSCustomO
