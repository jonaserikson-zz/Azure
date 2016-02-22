
param (

		[Parameter(Mandatory=$true)]
        [string]
        $CredStuff
    )


$CredsPath = "c:\temp\"
mkdir c:\temp
$SplitCredStuff = $CredStuff -split ';',2
#Write-Output $SplitCredStuff[1] | out-file $CredsPath$($SplitCredStuff[0])
Invoke-WebRequest -Uri $SplitCredStuff[0] | Out-File c:\temp\$SplitCredStuff[1]




#Remove-Item -Recurse -Force c:\temp
