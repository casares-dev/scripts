$DCName = "VDC01"

Rename-Computer -ComputerName $DCName -Force -PassThru
Set-NetIPInterface -InterfaceIndex 5 -Dhcp Disabled
New-NetIPAddress -InterfaceIndex 5 -AddressFamily IPv4 -IPAddress "10.0.2.3" -PrefixLength 16 -DefaultGateway "10.0.0.1"
Set-DnsClientServerAddress -InterfaceIndex 5 -ServerAddress "10.0.2.3" -PassThru
Enable-PSRemoting -Force
tzutil.exe /s "Eastern Standard Time"
Restart-Computer -Confirm
