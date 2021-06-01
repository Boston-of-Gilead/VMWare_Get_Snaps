$Admin = 'dom\admin'

#$Admin = Read-host -Prompt "Please enter your admin acct for the domain"
$aPassword = read-host -Prompt "Please enter your VMWare admin password" -AsSecureString
$encpassword = convertto-securestring $aPassword -asplaintext -force
$cred = new-object system.management.automation.pscredential($Admin,$encpassword)

$file = "c:\users\admin\desktop\snaps.txt"

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false

#Connect-VIServer -Server vmwareserver #-credential $Cred

#Gets SS >3 days old

$vmsnapshots = (Get-VM | Get-Snapshot) | Where {$_.Created -lt (Get-Date).AddDays(-3)} | Select-Object VM, Name, Created

$processed = 0

$results = @()

foreach ($snapshot in $vmsnapshots){

    Write-Progress -Activity "Getting snapshot CreatedBy info" -PercentComplete (($processed/$vmsnapshots.Length)*100)

    $processed = $processed + 1

    $snapevent = Get-VIEvent -Entity $snapshot.VM -Types Info -Finish $snapshot.Created -MaxSamples 1 | Where-Object {$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'}

    if ($snapevent -ne $null)
    {
        $user = [string]$snapevent.UserName
        $snapshot | Add-Member CreatedBy $user
    }
    else
    {
        $snapshot | Add-Member CreatedBy '--Unknown--'
    }
    $results = $results + $snapshot
}

Write-Progress -Activity "Sorting" -PercentComplete 0

$results = $results | Sort-Object -Property Created

Write-Progress -Completed -Activity "Sorting" -PercentComplete 100

$results | Format-Table -Property VM,Name,@{Label="Created"; Expression={Get-Date $_.Created -UFormat "%D"}},CreatedBy | Out-file $file