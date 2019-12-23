$ComputerName = Read-Host -Prompt "Please enter the computer name"
$session = New-PSSession -ComputerName $ComputerName
Copy-Item -Path "C:\LAPS" -Filter *.msi -Recurse -Verbose -Destination "C:\LAPS" -ToSession $session | Remove-PSSession
Invoke-Command -ComputerName $ComputerName -Credential (Get-Credential) -ScriptBlock {start-process "msiexec.exe /i "laps.x64.msi" ALLUSERS=1 /qn /norestart"}