@ECHO OFF

REM %~dp0 allows the this batch file to reside on a network share and correctly deploy the other two components of this script (PullUSB.xml and Get-FlashDriveFiles.ps1)
pushd %~dp0
cls
SET /p WORKSTATION=What is the target workstation name?

REM Copy the two worker files to the target workstation
copy PullUSB.xml \\%WORKSTATION%\C$\Users\Public\Options
copy Get-FlashDriveFiles.ps1 \\%WORKSTATION%\C$\Users\Public\Options

REM Schedule the task to watch for USB PNP events
schtasks /Create /TN CaptureUSB /S %WORKSTATION% /xml \\%WORKSTATION%\C$\Users\Public\Options\PullUSB.xml
pause
