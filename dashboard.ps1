$MyDashboard = New-UDDashboard -Title "My dashboard" -Content {
    
    New-UDCard -Title $env:COMPUTERNAME 
    New-UDChart -Type Bar -Endpoint {
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
                }
            )
        }
    }

   

    # enter ram chart here
    New-UDChart -Type Bar -Endpoint {
        $getram = get-wmiobject -Class win32_operatingsystem | Select-Object -property freephysicalmemory
        $getram | Format-List
    }

     # enter cpu chart here 
    #New-UDGrid -Title "CPU" -Endpoint{
    #    Get-WmiObject Win32_PhysicalMemory -Property capacity
    #}

}
Start-UDDashboard -Port 10000 -Dashboard $MyDashboard

