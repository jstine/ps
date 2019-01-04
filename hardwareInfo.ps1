Get-CimInstance -ClassName Win32_UserAccount | Select-Object Name,Caption,SID,Domain | Format-List
# Add -computername switch

Get-ComputerInfo | Select-Object -Property CsName,CsUsername,CsDomain,OsName,OsArchitecture,WindowsVersion,CsManufacturer,CsModel,CsProcessors | Format-List



