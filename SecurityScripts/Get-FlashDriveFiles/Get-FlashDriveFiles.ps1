#  Description:
#
# Works in parallel with the Scheduled Task "CaptureUSB" created by "PullUSB.xml" to watch the DriverFrameworks Operational event log for USB insertion events. 
# When the event is fired, this script is triggered and will scan for all USB drives inserted into the system. It will copy the contents of each drive to the C:\Users\Public\Options folder in unique folders for each drive.
#

# Allow Windows time to assign a drive letter 
Start-Sleep -s 10

# WMI Call to pull all connected USB Drive information

# Get assigned drive letter
$USBDriveLetter = Get-WmiObject Win32_DiskDrive | ?{$_.interfacetype -eq "USB"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | %{$_.deviceid}

# Get volume label of the USB drive
$USBVolume = Get-WmiObject Win32_DiskDrive | ?{$_.interfacetype -eq "USB"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | %{$_.volumename}

# Pull the size in bytes of the attached drive
$USBSize = Get-WmiObject Win32_DiskDrive | ?{$_.interfacetype -eq "USB"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | %{$_.size}

# To uniquely identify insertion events in the log file
$JobID = Get-Random
$Start= "*********************************************************** Started Job $JobID ***********************************************************" 
$Finished = "*********************************************************** Finished Job $JobID ***********************************************************"

# Create the log file
$Start  | Out-File -Filepath "C:\Users\Public\Options\USBLog.txt" -Append

Get-Date | Out-File -Filepath "C:\Users\Public\Options\USBLog.txt" -Append

# Write all potentially externally connected drives to the log
Get-WmiObject Win32_DiskDrive | ?{$_.interfacetype -eq "USB"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"}  | Out-File -Filepath "C:\Users\Public\Options\USBLog.txt" -Append
Get-WmiObject -Class Win32_PnPEntity -Namespace "root\CIMV2" | Where-Object {$_.Description -Like "Disk drive"} | Where-Object {$_.PNPDeviceID -Like 'USBSTOR*'} | Out-File -Filepath "C:\Users\Public\Options\USBLog.txt" -Append
Get-WmiObject -Class Win32_PnPEntity -Namespace "root\CIMV2" | Where-Object {$_.Description -Like "USB Mass Storage Device"}| Out-File -Filepath "C:\Users\Public\Options\USBLog.txt" -Append

$Finished | Out-File -Filepath "C:\Users\Public\Options\USBLog.txt" -Append

# Get current date and time and format for time stamping
$Date=Get-Date -UFormat "%Y-%m-%d-%T" | ForEach {$_ -replace ":","."}

# Initialize Arrays
$USBArray = @()
$USBLetterArray = @()
$USBVolumeArray = @()
$USBSizeArray = @()

# Set base destination path
$DestinationPath = "C:\Users\Public\Options\"

# Populate USB Arrays for multiple devices
$USBDriveLetter -replace '$','' | ForEach {$USBLetterArray+=$_} 
$USBVolume | ForEach {$USBVolumeArray+=$_}
$USBSize | ForEach {$USBSizeArray+=$_}

# Initialize counter
$i=0

# Copy files from each drive 
DO
{
  $tempFolderSize=0
  $tempDriveLetter = $USBLetterArray[$i] -replace ':',''

  # Formulate destination path: DriveLetter+VolumeName+TotalSize
  $tempPath=$tempDriveLetter+"-"+$USBVolumeArray[$i]+"-"+$USBSizeArray[$i]
  $tempJoinedPath=Join-Path $DestinationPath $tempPath

  # Check for existence of path, do not overwrite if it already exists
  if (!(Test-Path $tempJoinedPath)) 
    {
        # If the path does not yet exist, create it and copy the contents of the flash drive to this path
        mkdir $tempJoinedPath

        # Using ROBOCOPY to perform the copy operation. MT is a multithreaded copy using 32 threads. Log file is written to target directory
        Get-ChildItem -Recurse $USBLetterArray[$i]  | select fullname,length,lastwritetime,creationtime,extension | Export-Csv $tempJoinedPath\FileList.csv -NoTypeInformation
        robocopy $USBLetterArray[$i] $tempJoinedPath /E /COPY:DAT /DCOPY:T /MT:32 /LOG+:$tempJoinedPath\robocopy.txt
    }
  else
    {
        # If the path exists, let's test to see if it is empty. If it is empty, we will overwrite it with the contents of the flash drive
        $tempFolderSize=Get-ChildItem $tempJoinedPath | Measure-Object -Property Length -Sum
        if ($tempFolderSize.Sum -ge 1) 
            {
                # Directory is not empty, continue with the loop for any other flash drives
                Write-Output "$date -- Folder Exists: $tempJoinedPath" | Out-File $tempJoinedPath\USBAttempt.txt -Append
                $i++
                continue
            }
        else
            {
                # Directory exists but is empty, overwrite with files from the flash drive
                # Using ROBOCOPY to perform the copy operation. MT is a multithreaded copy using 32 threads. Log file is written to target directory
                robocopy $USBLetterArray[$i] $tempJoinedPath /E /COPY:DAT /DCOPY:T /MT:32 /LOG+:$temp\robocopy.txt
            }
    }

  $i++
} While ($i -le $USBLetterArray.Length-1)

Exit
