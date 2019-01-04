$size = @{Name="GB";Expression={[math]::round($_.size/1GB,2)}}
$free = @{Name="Freespace";Expression={[math]::round($_.freespace/1GB,2)}}
$used = @{Name="Used";Expression={[math]::round(($_.size-$_.freespace) /1GB,2)}}
$pctused = @{Name="Pct Used";Expression={(($_.size-$_.freespace)/$_.size).ToString("P")}}
$pctfree = @{Name="Pct Free";Expression={($_.freespace/$_.size).ToString("P")}}
Get-WmiObject -Class win32_logicaldisk | Select-Object DeviceID, $size, $free, $used, $pctfree, $pctused | Format-List

