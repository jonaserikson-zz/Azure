
param (

		[Parameter(Mandatory=$true)]
        [string]
        $CredsFilename,

      [Parameter(Mandatory=$true)]
          [string]
          $CredsContent
    )

$CredsPath = "c:\temp\"

mkdir c:\temp
Write-Output $CredsContent | out-file $CredsPath$CredsFilename
