
param (

		[Parameter(Mandatory=$true)]
        [string]
        $Arguments
    )

$CredsPath = "c:\temp\"

mkdir c:\temp
Write-Output $Arguments.CredsContent | out-file $CredsPath$Arguments.CredsFilename
