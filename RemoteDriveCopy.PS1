# needs to be expanded to monitor drive insertion/detect drives that are not D/E
#

$remotecomputer = "COMPUTERNAME"
$toemailaddress = "toemailaddress"
$fromemailaddress = "fromemailaddress"
$emailserver = "emailserver"
$directorylocation = "directorylocation"
$copylocation = "copylocation"

$Root = Invoke-Command -ComputerName $remotecomputer {Get-PSDrive | select Root}
If ($Root -like "*E:\*") {
Invoke-Command -computername $remotecomputer {net share e$=e:\}
Send-MailMessage -to $toemailaddress -Subject "copy started" -from $fromemailaddress -SmtpServer $emailserver
Get-ChildItem -Recurse "\\$remotecomputer\e$\" | Select-Object FullName | out-file "$directorylocation"
Copy-Item -Recurse "\\$remotecomputer\e$\" "$copylocation"
Send-MailMessage -to $toemailaddress -Subject "copy complete" -from $fromemailaddress -SmtpServer $emailserver
}
elseif ($Root -like "*D:\*") {  
Invoke-Command -computername $remotecomputer {net share d$=d:\}
Send-MailMessage -to $toemailaddress -Subject "copy started" -from $fromemailaddress -SmtpServer $emailserver
Get-ChildItem -Recurse "\\$remotecomputer\d$\" | Select-Object FullName | out-file "$directorylocation"
Copy-Item -Recurse "\\$remotecomputer\d$\" "$copylocation"
Send-MailMessage -to $toemailaddress -Subject "copy complete" -from $fromemailaddress -SmtpServer $emailserver
}
else { write-host "None of the available drives are available"}
