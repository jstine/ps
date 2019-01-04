$MyDashboard = New-UDDashboard -Title "My dashboard" -Content{
    New-UDCard -Title $env:COMPUTERNAME 
    New-UDRow -Columns {              
        New-UDColumn -Size 4 {
            New-UDMonitor -Title "RAM Usage" -Type Line -DataPointHistory 50 -RefreshInterval 5 -Endpoint {
                (get-wmiobject win32_operatingsystem).freephysicalmemory | Out-UDMonitorData 
            }
    }              
        New-UDColumn -Size 4 {
            New-UdMonitor -Title "CPU (% processor time)" -Type Line -DataPointHistory 60 -RefreshInterval 5 -ChartBackgroundColor '#80FF6B63' -ChartBorderColor '#FFFF6B63'  -Endpoint {
                Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue | Out-UDMonitorData
           }
    }         
        New-UDColumn -Size 4 {
            New-UDChart -Title "Drive Space" -Type Bar -Endpoint {
                Get-CimInstance -ClassName Win32_LogicalDisk | ForEach-Object {
                    [PSCustomObject]@{ DeviceId = $_.DeviceID;
                                  Size = [Math]::Round($_.Size / 1GB, 2);
                                  FreeSpace = [Math]::Round($_.FreeSpace / 1GB, 2); } } | Out-UDChartData -LabelProperty "DeviceID" -Dataset @(
                 New-UdChartDataset -DataProperty "Size" -Label "Size" -BackgroundColor "#80962F23" -HoverBackgroundColor "#80962F23"
                 New-UdChartDataset -DataProperty "FreeSpace" -Label "Free Space" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C"
             )
            } -Labels @("Process Memory") -Options @{
                scales = @{
                    xAxes = @(
                        @{
                            stacked = $true
                        }
                    )
                    yAxes = @(
                        @{
                            stacked = $true
                        })}}}}
   #New-UDMonitor -Title "\FileSystem Disk Activity(*)\FileSystem Bytes Written" -Type Line -DataPointHistory 60 -RefreshInterval 5 -Endpoint{
    #   Get-Counter '\FileSystem Disk Activity(*)\FileSystem Bytes Written' -ErrorAction SilentlyContinue | Out-UDMonitorData
   #}
 



   New-UDRow -Columns {              
    New-UDColumn -Size 6 {
        New-UdGrid -Title "Processes" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint {
            Get-Process | Select-Object Name,ID,WorkingSet,CPU | Out-UDGridData
        }
}              
    New-UDColumn -Size 6 {
        New-UDChart -Title "Threads by Process" -Type Doughnut -RefreshInterval 5 -Endpoint {  
            Get-Process | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Threads = $_.Threads.Count } } | Out-UDChartData -DataProperty "Threads" -LabelProperty "Name"  
        } -Options @{  
             legend = @{  
                 display = $false  
             }  
           }
}              
}   

New-UdGrid -Title "Disk" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint {
   #(Get-Counter -List PhysicalDisk).PathsWithInstances | Out-UDGridData
}

New-UdMonitor -Title "CPU (% processor time)" -Type Line -DataPointHistory 60 -RefreshInterval 5 -ChartBackgroundColor '#80FF6B63' -ChartBorderColor '#FFFF6B63'  -Endpoint {
    (Get-Counter -List PhysicalDisk).PathsWithInstances | Out-UDMonitorData 
}



}
Start-UDDashboard -Port 10000 -Dashboard $MyDashboard




