$getram = get-wmiobject -Class win32_operatingsystem | Select-Object -property freephysicalmemory
$getram | Format-List