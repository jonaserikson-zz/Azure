
param (

		[Parameter(Mandatory=$true)]
        [string]
        $CredStuff
    )


$CredsPath = "c:\temp\"
mkdir c:\temp
$SplitCredStuff = $CredStuff.Split(";")[0]
Write-Output $SplitCredStuff[1] | out-file $CredsPath$($SplitCredStuff[0])




#Remove-Item -Recurse -Force c:\temp
