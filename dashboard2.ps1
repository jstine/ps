#import-module D:\Scripts\Powershell\influxdb.psm1
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
#disk io errors
#disk usage
#ram threshold
#something using ram high for too long, kill that thread
#network | if torrenting, dump to file and report to us
#write all to database
#set up thresholds
#use thresholds to create reports
#format reports to html and make pretty
#influxdb for db
#new dashboard for assets
#new dashboard for wiki
#dashboard for monitoring anything that SC cannot
   

New-UdGrid -Title "Disk" -Headers @("Name", "ID", "Working Set", "CPU") -Properties @("Name", "Id", "WorkingSet", "CPU") -AutoRefresh -RefreshInterval 60 -Endpoint {
   #(Get-Counter -List PhysicalDisk).PathsWithInstances | Out-UDGridData
}

New-UdMonitor -Title "CPU (% processor time)" -Type Line -DataPointHistory 60 -RefreshInterval 5 -ChartBackgroundColor '#80FF6B63' -ChartBorderColor '#FFFF6B63'  -Endpoint {
    (Get-Counter -List PhysicalDisk).PathsWithInstances | Out-UDMonitorData 
}
# do db stuff in here
$Schedule = New-UDEndpointSchedule -Every 5 -Second
$Endpoint = New-UDEndpoint -Schedule $Schedule -Endpoint {

    $InfluxUrl = "http://localhost:8086/write?db=performance_data"
    # convert from millisecnod to nanosecond
    $TimeStamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds() * 1000000

    $PerformanceStats = @(
        '\Processor(_Total)\% Processor Time'
        '\memory\% committed bytes in use'
        '\physicaldisk(_total)\% disk time'
    )

    foreach($PerformanceStat in $PerformanceStats) {
        $Value = 0
        (Get-Counter $PerformanceStat).CounterSamples | ForEach-Object {
            $Value += $_.CookedValue
        }
        Invoke-RestMethod -Method POST -Uri $InfluxUrl -Body "counter,host=$env:COMPUTERNAME,
        counter=$($PerformanceStat.Replace(' ', '\ ')) value=$value $timestamp"
    }


}
# query db for data
$Data = Get-InfluxDb -Query 'SELECT * FROM counter WHERE time > now() - 5m GROUP by counter'

# set up data for nivo chart - requires hashtable with x and y values for each point in chart
$ChartData = @()

foreach($series in $data){
    $SeriesData = @{
        id = $series.counter
        data = @()
    }
}
foreach($field in $Series.fields){
    $SeriesData.data += @{
        x = $field.time
        y = $field.value
    }
}

$ChartData += $SeriesData

$BottomAxis = New-UdNivoChartAxisOptions -TickRotation 90
New-UDNivoChart -Data $ChartData -Id "performanceStats" -Line -Responsive -MarginBottom 5 0 -MarginTop 50 -MarginRight 110 -Marginleft 60 -YScaleMax 100 -YScaleMin 0 -EnableArea -AxisBottom $BottomAxis -Colors 'paired'

New-UDElement -Tag 'div' -Attributes @{ style = @{ "height" = '400px'}} -AutoRefresh -RefreshInterval 5 -Endpoint {
    # Chart code ()
}



}
Start-UDDashboard -Port 10000 -Dashboard $MyDashboard




