Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
Import-Module ServerManager

## variables############################################################################################################
$DomainName = "void.lab"
$AD_Database_Path = "C:"

########################################################################################################################
##### start of script ###### start of script ###### start of script ###### start of script ###### start of script ######
########################################################################################################################
$Date = Get-Date -f yyyyMMddhhmm

## creates location to store temporary files############################################################################
New-Item -Path "C:\" -Name "tmp" -ItemType "directory"
$wshshell = New-Object -ComObject WScript.Shell

$OutputPath = "C:\tmp"

## verify server information############################################################################################
function Get-SystemInfo 
{ 
  param($ComputerName = $env:ComputerName) 
  
      $header = 'Hostname','OSName','OSVersion','OSManufacturer','OSConfig','Buildtype', 'RegisteredOwner','RegisteredOrganization','ProductID','InstallDate', 'StartTime','Manufacturer','Model','Type','Processor','BIOSVersion', 'WindowsFolder' ,'SystemFolder','StartDevice','Culture', 'UICulture', 'TimeZone','PhysicalMemory', 'AvailablePhysicalMemory' , 'MaxVirtualMemory', 'AvailableVirtualMemory','UsedVirtualMemory','PagingFile','Domain' ,'LogonServer','Hotfix','NetworkAdapter' 
      systeminfo.exe /FO CSV /S $ComputerName |  
            Select-Object -Skip 1 |  
            ConvertFrom-CSV -Header $header 
} 
Get-SystemInfo -ComputerName $env:COMPUTERNAME
$a = new-object -comobject wscript.shell
$b = $a.popup("Please confirm the System Information, specifically the HostName and IP Address. Press OK to CONTINUE or Cancel to STOP if there is an error.",0,"Please confirm SysInfo:",1)
Get-SystemInfo -ComputerName $env:COMPUTERNAME | Out-File -FilePath "$OutputPath\SysInfo-$Date.csv" -Force

## Installs Active Directory Domain Services & DNS######################################################################
Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools

## creates the domain###################################################################################################
Import-Module ADDSDeployment
Import-Module DnsServer
Install-ADDSForest -DomainName $DomainName -InstallDns -DomainMode WinThreshold -ForestMode WinThreshold -DatabasePath $AD_Database_Path\Windows\NTDS -SysvolPath $AD_Database_Path\Windows\SYSVOL -LogPath $AD_Database_Path\Windows\Logs -Force
