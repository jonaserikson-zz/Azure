
param (

		[Parameter(Mandatory=$true)]
        [string]
        $CredStuff
    )


$CredsPath = "c:\temp\"
mkdir c:\temp
$SplitCredStuff = $CredStuff -split ';',2
Write-Output $SplitCredStuff[1] | out-file $CredsPath$($SplitCredStuff[0])




#Remove-Item -Recurse -Force c:\temp
