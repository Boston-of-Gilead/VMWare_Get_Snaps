Connect-VIServer -Server vcenter01 -User admin -Password pass

#Gets SS >3 days old
Get-VM | Get-Snapshot | Where {$_.Created -lt (Get-Date).AddDays(-3)} | Select-Object VM, Name, Created