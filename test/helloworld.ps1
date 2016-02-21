
param (

		[Parameter(Mandatory=$true)]
        [string]
        $Arguments
    )

$CredsPath = "c:\temp\"
$SplitArgument = $Argument.Split(";")
mkdir c:\temp
Write-Output $SplitArguments[1] | out-file $CredsPath$SplitArguments[0]
