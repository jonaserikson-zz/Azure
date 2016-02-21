
param (

		[Parameter(Mandatory=$true)]
        [string]
        $CredStuff
    )

$CredsPath = "c:\temp\"
$SplitCredStuff = $CredStuff.Split(";")
mkdir c:\temp
Write-Output $SplitCredStuff[1] | out-file $CredsPath$SplitCredStuff[0]




#Remove-Item -Recurse -Force c:\temp
