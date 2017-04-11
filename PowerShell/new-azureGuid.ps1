$nhGuid= (New-Guid).Guid -replace '-',''
$aGuid = $nhGuid.substring(0,11)
$aGuid







$genAuid1 = ([char[]]([char]'a'..[char]'z')| sort {get-random})[1]
$genAuid2 = ([char[]]([char]'a'..[char]'z') + 0..9 | sort {get-random})[0..10] -join ''
$Auid = $genAuid1 + $genAuid2
