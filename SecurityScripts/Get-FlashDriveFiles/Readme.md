1. DeployFlashDriveWatch.bat - handles copying the PS script and task XML to the target machine. 
   Also handles registering the task to trigger on insertion events.
  
2. PullUSB.xml - Task to monitor for PNP events and triggers the PS script on EventCode 2006

3. Get-FlashDriveFiles.ps1 - the actual script to copy files from inserted drives.

You stage all three files in the same folder (local or network). 
Then only run DeployFlashDriveWatch.bat, which will copy the other two files to
the destination workstation and schedule the task. You may need to run the batch 
file as a different user if you have an administrative account you need to use to actually reach the endpoint.
