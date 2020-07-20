Import-Module ActiveDirectory

## variables############################################################################################################
Function Select-FolderDialog
{
    param([string]$Description="Select the file: kit_ADDS...",[string]$RootFolder="Desktop")

 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
     Out-Null     

   $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
        $objForm.Rootfolder = $RootFolder
        $objForm.Description = $Description
        $Show = $objForm.ShowDialog()
        If ($Show -eq "OK")
        {
            Return $objForm.SelectedPath
        }
        Else
        {
            Write-Error "Operation cancelled by user."
        }
    }
$select_path = Select-FolderDialog

########################################################################################################################
##### start of script ###### start of script ###### start of script ###### start of script ###### start of script ######
########################################################################################################################
$Date = Get-Date -f yyyyMMddhhmm
$wmiDomain = Get-WmiObject Win32_NTDomain -Filter "DnsForestName = '$( (Get-WmiObject Win32_ComputerSystem).Domain)'"
$SrceDN = $wmiDomain.DomainName
$DomainDN = Get-ADDomain -Current LocalComputer | Select-Object -ExpandProperty DistinguishedName

## creates location to store temporary files############################################################################
New-Item -Path "C:\" -Name "$SrceDN" -ItemType "directory"
$wshshell = New-Object -ComObject WScript.Shell
$desktop = [System.Environment]::GetFolderPath('Desktop')
  $lnk = $wshshell.CreateShortcut($desktop+"\tmp.lnk")
  $lnk.TargetPath = "C:\$SrceDN"
  $lnk.Save() 

$Domain_Files = "C:\$SrceDN"

## Enabling AD DS Features##############################################################################################
auditpol /set /subcategory:"directory service changes" /success:enable
Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $env:USERDNSDOMAIN -Confirm:$false
Add-KDSRootKey -EffectiveTime ((get-date).addhours(-10))  

## Active Directory Domains and Trusts##################################################################################
Import-Module "$select_path\PSfunc\ADTrust.psm1"
$TrustReq = new-object -comobject wscript.shell 
$TrustInput = $TrustReq.popup("Does this Domain require a Domain trust?", 0,"Active Directory Trusts",4) 
If ($TrustInput -eq 6) { 
    $RemoteForest = Read-Host -Prompt "Provide the FQDN of the Trusted Domain"
    $RemoteForestIP = Read-Host -Prompt "Provide the IP to the PDCe of the Trusted Domain"
    Add-DnsServerConditionalForwarderZone -Name "$RemoteForest" -MasterServers "$RemoteForestIP" -ReplicationScope Forest 
    $TrustCreds = $Host.ui.PromptForCredential("Remote Domain Credentials", "Enter $RemoteForest\Username Credentials", "", "NetBiosUserName")
    $RemoteAdmin = $TrustCreds.getNetworkCredential().username
    $RemotePassword = $TrustCreds.getNetworkCredential().password
    $targetForest = $RemoteForest
 
    $options = [System.Management.Automation.Host.ChoiceDescription[]] @("Inbound", "Outbound", "Bidirectional")
    [int]$defaultchoice = 2
    $opt = $host.UI.PromptForChoice("Domain Trust Direction", "Please select the appropriate Trust Direction", $Options,$defaultchoice)
    switch($opt)
        {
            0 { New-ADForestTrust -RemoteForest $RemoteForest -RemoteAdmin $RemoteAdmin -RemotePassword $RemotePassword -TrustDirection Inbound }
            1 { New-ADForestTrust -RemoteForest $RemoteForest -RemoteAdmin $RemoteAdmin -RemotePassword $RemotePassword -TrustDirection Outbound }
            2 { New-ADForestTrust -RemoteForest $RemoteForest -RemoteAdmin $RemoteAdmin -RemotePassword $RemotePassword -TrustDirection Bidirectional }
        }
} else { 
    $TrustReq.popup("None will be configured.") 
} 

## Active Directory Sites and Services##################################################################################
#### Create Primary Subnet
$SubnetIP = Read-Host -Prompt "Provide the IP/Mask for the primary Subnet"
New-ADReplicationSubnet -Name $SubnetIP -Site "Default-First-Site-Name"
Add-DnsServerPrimaryZone -NetworkId "$SubnetIP" -ReplicationScope Forest

#### Rename Default-First-Site-Name
$DefaultSiteRename = Read-Host -Prompt "Provide a valid name for the default AD Site, Default-First-Site-Name: <NoSpaces>"
Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -filter "objectclass -eq 'site'" | Set-ADObject -DisplayName $DefaultSiteRename
Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -filter "objectclass -eq 'site'" | Rename-ADObject -NewName $DefaultSiteRename

#### Create additional Sites
$SiteReq = new-object -comobject wscript.shell
$SiteInput = $SiteReq.popup("Does this Domain require Additional Sites?", 0,"Active Directory Sites",4)
If ($SiteInput -eq 6) {
    Do {
        $SiteName = Read-Host -Prompt "Provide the name for the additional Site"
        New-ADReplicationSite $SiteName
        $SiteAdditional = $SiteReq.popup("Does this Domain require Additional Sites?", 0,"Active Directory Sites",4)
    } While ($SiteAdditional -eq 6)
} else { 
        $SiteReq.popup("No additional Sites will be configured.") 
        }
Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -filter "objectclass -eq 'site'" | Set-ADObject -ProtectedFromAccidentalDeletion 1

#### Create additional Subnets
$SubnetReq = new-object -comobject wscript.shell
$SubnetInput = $SubnetReq.popup("Does this Domain require Subnets configured?", 0,"Active Directory Subnets",4)
If ($SubnetInput -eq 6) {
    Do {
        $SubnetIP = Read-Host -Prompt "Provide the IP/Mask for the additional Subnet"
        $SubnetSite = Read-Host -Prompt "Which Site is this Subnet associated with"
        New-ADReplicationSubnet -Name $SubnetIP -Site $SubnetSite
        Add-DnsServerPrimaryZone -NetworkId "$SubnetIP" -ReplicationScope Forest
        $SubnetAdditional = $SubnetReq.popup("Does this Domain require Additional Subnets?", 0,"Active Directory Subnets",4)
    } While ($SubnetAdditional -eq 6)
} else { 
        $SubnetReq.popup("No Subnets will be configured.") 
        }
Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -filter "objectclass -eq 'subnet'" | Set-ADObject -ProtectedFromAccidentalDeletion 1

## Active Directory Users and Computers#################################################################################
#### Create OU structure
New-ADOrganizationalUnit -Name "$SrceDN" -Path $DomainDN
New-ADOrganizationalUnit -Name "Domain Groups" -Path "OU=$SrceDN,$DomainDN"
New-ADOrganizationalUnit -Name "Servers" -Path "OU=$SrceDN,$DomainDN"
New-ADOrganizationalUnit -Name "Service Accounts" -Path "OU=$SrceDN,$DomainDN"
New-ADOrganizationalUnit -Name "Users" -Path "OU=$SrceDN,$DomainDN"
New-ADOrganizationalUnit -Name "Disabled Users" -Path "OU=Users,OU=$SrceDN,$DomainDN"

#### Create ADUC Groups
New-ADGroup -Name "svc_$SrceDN" -GroupCategory Security -GroupScope Global -Description "ALL service accounts" -path "OU=Domain Groups,OU=$SrceDN,$DomainDN"
New-ADGroup -Name "usr_$SrceDN" -GroupCategory Security -GroupScope Global -Description "ALL user accounts" -path "OU=Domain Groups,OU=$SrceDN,$DomainDN"

#### Create Group Managed Service Accounts for AD DS
New-ADServiceAccount -Name "DC-SchTsk" -DNSHostName "DC-SchTsk.$env:USERDNSDOMAIN" -PrincipalsAllowedToRetrieveManagedPassword "Domain Controllers","Domain Admins"
Install-ADServiceAccount -Identity "DC-SchTsk"
Test-ADServiceAccount -Identity "DC-SchTsk"

## Fine-Grained Password Policies, PSO##################################################################################
## MS Best Practices | -MinPasswordLength 14 -MaxPasswordAge "90.00:00:00" -MinPasswordAge "1.00:00:00" -PasswordHistoryCount 24 -LockoutThreshold 5 -LockoutDuration "0.00:60:00" -ComplexityEnabled $true 
## CIS | -MinPasswordLength 14 -MaxPasswordAge "60.00:00:00" -MinPasswordAge "1.00:00:00" -PasswordHistoryCount 24 -LockoutThreshold 5 -LockoutDuration "0.00:60:00" -ComplexityEnabled $true 
## NIST | -MinPasswordLength 8 -MaxPasswordAge "00.00:00:00" -MinPasswordAge "1.00:00:00" -PasswordHistoryCount 24 -LockoutThreshold 3 -ComplexityEnabled $false 
## HITRUST | -MinPasswordLength 8 -MaxPasswordAge "90.00:00:00" -MinPasswordAge "1.00:00:00" -PasswordHistoryCount 6 -LockoutThreshold 3 -LockoutDuration "0.03:00:00" -ComplexityEnabled $true #privileged accounts reset every 60 days

#### Creates a PSO for accounts whose password does not expire, ie. service accounts
New-ADFineGrainedPasswordPolicy -Precedence 1 -Name PSO_desNOTexp -DisplayName PSO_desNOTexp -Description "PSO for accounts whose password does NOT expire" -ReversibleEncryptionEnabled $false -ProtectedFromAccidentalDeletion $true
Add-ADFineGrainedPasswordPolicySubject PSO_desNOTexp -Subjects "svc_$SrceDN"

#### Creates a PSO for accounts that require a more strict password, ie. domain admins
New-ADFineGrainedPasswordPolicy -Precedence 5 -Name PSO_IncSec -DisplayName PSO_IncSec -Description "PSO for accounts that require a more strict password" -ReversibleEncryptionEnabled $false -ProtectedFromAccidentalDeletion $true
Add-ADFineGrainedPasswordPolicySubject PSO_IncSec -Subjects "Domain Admins"

#### Creates a PSO for basic user accounts, ie. domain users
New-ADFineGrainedPasswordPolicy -Precedence 10 -Name PSO_BasicSec -DisplayName PSO_BasicSec -Description "PSO for basic user accounts" -ReversibleEncryptionEnabled $false -ProtectedFromAccidentalDeletion $true
Add-ADFineGrainedPasswordPolicySubject PSO_BasicSec -Subjects "usr_$SrceDN"

## DNS##################################################################################################################
$DNSfwd = Read-Host -Prompt "Configure at least ONE DNS Forwarder"
Add-DnsServerForwarder -IPAddress $DNSfwd -PassThru
Set-DnsServerScavenging -ScavengingState $true -RefreshInterval 7.00:00:00 -ScavengingInterval 30.00:00:00 -Verbose -PassThru

## GPO##################################################################################################################
Import-Module GroupPolicy
Import-Module "$select_path\PSfunc\GPWmiFilter.psm1"
New-GPWmiFilter -Name 'Domain Controller PDCe' -Expression 'Select * from Win32_ComputerSystem where DomainRole = "5"' -Description 'Queries for the domain controller that holds the PDCe FSMO role' -PassThru
New-GPWmiFilter -Name 'Domain Controllers' -Expression 'Select * from Win32_OperatingSystem where ProductType= "2"' -Description 'Targets ALL Domain Controllers' -PassThru
New-GPWmiFilter -Name 'Member Servers' -Expression 'Select * from Win32_OperatingSystem where ProductType= "3"' -Description 'Targets ALL Member Servers' -PassThru
New-GPWmiFilter -Name 'Windows Server 2008 R2 Domain Controller' -Expression 'Select Version,ProductType FROM Win32_OperatingSystem WHERE Version LIKE "6.1%" AND ProductType = "2"' -Description 'Windows Server 2008 R2 Domain Controller' -PassThru
New-GPWmiFilter -Name 'Windows Server 2008 R2 Member Server' -Expression 'Select Version,ProductType FROM Win32_OperatingSystem WHERE Version like "6.1%" AND ProductType = "3"' -Description 'Windows Server 2008 R2 Member Server' -PassThru
New-GPWmiFilter -Name 'Windows Server 2012 R2 Domain Controller' -Expression 'Select Version,ProductType FROM Win32_OperatingSystem WHERE Version LIKE "6.3%" AND ProductType = "2"' -Description 'Windows Server 2012 R2 Domain Controller' -PassThru
New-GPWmiFilter -Name 'Windows Server 2012 R2 Member Server' -Expression 'Select Version,ProductType FROM Win32_OperatingSystem WHERE Version LIKE "6.3%" AND ProductType = "3"' -Description 'Windows Server 2012 R2 Member Server' -PassThru
New-GPWmiFilter -Name 'Windows Server 2016 Domain Controller' -Expression 'Select Version,ProductType FROM Win32_OperatingSystem WHERE Version LIKE "10.%" AND ProductType = "2"' -Description 'Windows Server 2016 Domain Controller' -PassThru
New-GPWmiFilter -Name 'Windows Server 2016 Member Server' -Expression 'Select Version,ProductType FROM Win32_OperatingSystem WHERE Version LIKE "10.%" AND ProductType = "3"' -Description 'Windows Server 2016 Member Server' -PassThru

## Scheduled Tasks######################################################################################################
Copy-Item "$select_path\TaskScheduler\" -Destination $Domain_Files -Recurse -Force
$TaskScript = "$Domain_Files\TaskScheduler"
$gMSA = "$SrceDN\DC-SchTsk$"

#### ADUser_MoveAgedDisabled
$SchTskName = "ADUser_MoveAgedDisabled"
$principal = New-ScheduledTaskPrincipal -UserId $gMSA -LogonType Password -RunLevel Highest
$TaskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8 -ExecutionTimeLimit 00:15:00 -AllowStartIfOnBatteries
$trigger = New-ScheduledTaskTrigger -At 23:00:00 -Daily 
$action = New-ScheduledTaskAction -Execute "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument "$TaskScript\ADUser_MoveAgedDisabled.ps1"
$Task = Register-ScheduledTask $SchTskName -Description "Searches Active Directory for aged accounts, excluding Client OU, then disables and moves them to a Disabled OU; C:\tmp\DisableAgedMove.csv" -Action $action -Trigger $trigger -Principal $principal -Settings $TaskSettings
$Task | Set-ScheduledTask
schtasks /Change /TN $SchTskName /RU $gMSA /RP ""

#### FileCleanup-Tmp
$SchTskName = "FileCleanup-Tmp"
$principal = New-ScheduledTaskPrincipal -UserId $gMSA -LogonType Password -RunLevel Highest
$TaskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8 -ExecutionTimeLimit 00:15:00 -AllowStartIfOnBatteries 
$trigger = New-ScheduledTaskTrigger -At 23:00:00 -Daily
$action = New-ScheduledTaskAction -Execute "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument "$TaskScript\FileCleanup-Tmp_Remove-Item_OlderThan.ps1"
$Task = Register-ScheduledTask $SchTskName -Description "Task removes files from C:\TMP older than 30days" -Action $action -Trigger $trigger -Principal $principal -Settings $TaskSettings
$Task | Set-ScheduledTask
schtasks /Change /TN $SchTskName /RU $gMSA /RP ""

#### PrivilegedGroups
$SchTskName = "ADDS_PrivilegedGroups"
$principal = New-ScheduledTaskPrincipal -UserId $gMSA -LogonType Password -RunLevel Highest
$TaskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8 -ExecutionTimeLimit 00:15:00 -AllowStartIfOnBatteries 
$trigger = New-ScheduledTaskTrigger -At 23:00:00 -Daily
$action = New-ScheduledTaskAction -Execute "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument "$TaskScript\PrivilegedGroupChanges_DisplaysChanges.ps1"
$Task = Register-ScheduledTask $SchTskName -Description "Documents modificaitons to Privileged Groups; C:\tmp\PrivGroupMembershipChanges.csv" -Action $action -Trigger $trigger -Principal $principal -Settings $TaskSettings
$Task | Set-ScheduledTask
schtasks /Change /TN $SchTskName /RU $gMSA /RP ""

## Delete Deployment Kit################################################################################################
Remove-Item –path $select_path –recurse