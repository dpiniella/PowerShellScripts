# find out why a user is locked out, checking multiple DCs
# requires a DCs.txt file with Domain Controllers, 1 per line
#
# exports to LockedUsers.csv on Desktop from running users
#

$DCs = Get-Content -Path \path\to\DCs.txt
$Properties = @(
    @{n='User';e={$_.Properties[0].Value}},
    @{n='Locked by';e={$_.Properties[1].Value}},
    @{n='TimeStamp';e={$_.TimeCreated}}
    @{n='DCname';e={$_.Properties[4].Value}}
)

Invoke-Command -ComputerName $DCs -ScriptBlock {
    Get-WinEvent -FilterHashTable @{LogName='Security'; ID=4740} | 
    Select $Using:Properties
} |

Export-csv C:\Users\$env:username\Desktop\LockedUsers.csv -NoTypeInformation -Encoding UTF8
