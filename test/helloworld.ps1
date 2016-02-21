mkdir c:\temp
$GetArgument = $Argument
#$SplitArgument = $Argument.Split(";")
#Write-Output "Hello World" | out-file c:\temp\helloworld.txt
Write-Output $GetArgument | out-file c:\temp\helloworld.txt
