Import-Module UniversalDashboard

Get-UDDashboard | Stop-UDDashboard

$EI = New-UDEndpointInitialization -Module (Join-Path $PSScriptRoot 'influxdb.psm1')

$Cache:NetworkStats = @(
    '\network adapter(*)\bytes received/sec'
    '\network adapter(*)\bytes sent/sec'
)

$Schedule = New-UDEndpointSchedule -Every 5 -Second
$Endpoint = New-UDEndpoint -Schedule $Schedule -Endpoint {
    $InfluxUrl =  "http://localhost:8086/write?db=performance_data"
    $TimeStamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds() * 1000000

    Get-Process | ForEach-Object {

        $Cpu = $_.CPU
        if ($Cpu -eq $null) {
            $CPU = 0
        }

        Invoke-RestMethod -Method POST -Uri $InfluxUrl -Body "process,host=$ENV:COMPUTERNAME,process=$($_.Name.Replace(' ', "\ ")) workingset=$($_.WorkingSet),cpu=$CPU,handle_count=$($_.HandleCount),thread_count=$($_.threats.count) $TimeStamp"
    }

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

        Invoke-RestMethod -Method POST -Uri $InfluxUrl -Body "counter,host=$ENV:COMPUTERNAME,counter=$($PerformanceStat.Replace(' ', '\ ')) value=$value $TimeStamp"
    }

    foreach($PerformanceStat in $Cache:NetworkStats) {
        $Value = 0
        (Get-Counter $PerformanceStat).CounterSamples | ForEach-Object {
            $Value += $_.CookedValue
        }

        Invoke-RestMethod -Method POST -Uri $InfluxUrl -Body "network,host=$ENV:COMPUTERNAME,counter=$($PerformanceStat.Replace(' ', '\ ')) value=$value $TimeStamp"
    }

    Get-CimInstance -ClassName Win32_LogicalDisk | ForEach-Object {
        $FreeSpace = $_.FreeSpace
        $UsedSpace = $_.Size - $_.FreeSpace

        Invoke-RestMethod -Method POST -Uri $InfluxUrl -Body "disk,host=$ENV:COMPUTERNAME,device_id=$($_.DeviceID) free_space=$FreeSpace,used_space=$UsedSpace $TimeStamp"
    } 
}

Start-UDDashboard -Content {
    New-UDDashboard -EndpointInitialization $EI -Title "Server Performance Dashboard" -NavBarColor 'black' -NavBarFontColor 'white' -Content {

        New-UDRow -Columns {
            New-UDColumn -SmallSize 12 -Content {
                New-UDHeading -Text "$ENV:ComputerName" -Size 4
            }
        }

        New-UDRow -Columns {
            
        }

        New-UDRow -Columns {
            New-UDColumn -SmallSize 12 -Content {
                New-UDCard -Title "Performance Metrics" -Content {
                    New-UDElement -Tag 'div' -Attributes @{ style = @{ "height" = '400px'}} -AutoRefresh -RefreshInterval 5 -Endpoint {

                        $Data = Get-InfluxDb -Query 'SELECT * FROM counter WHERE time > now() - 5m GROUP BY counter'

                        $ChartData = @()

                        foreach($series in $data) {

                            $SeriesData = @{
                                id =  $series.counter
                                data = @()
                            }

                            foreach($field in $Series.Fields) {
                                $SeriesData.data += @{
                                    x = $field.time
                                    y = $field.value
                                }                        
                            }

                            $ChartData += $SeriesData
                        }

                        $BottomAxis = New-UDNivoChartAxisOptions -TickRotation 90
                        New-UDNivoChart -Data $ChartData -Id "performanceStats" -Line -Responsive -MarginBottom 50 -MarginTop 50 -MarginRight 110 -MarginLeft 60 -YScaleMax 100 -YScaleMin 0 -EnableArea -AxisBottom $BottomAxis -Colors 'paired'
                    }
                }
            }
        }

        New-UDRow -Columns {
            New-UDColumn -SmallSize 12 -Content {
                New-UDCard -Title "Network Traffic" -Content {
                    New-UDElement -Tag 'div' -Attributes @{ style = @{ "height" = '400px'}} -AutoRefresh -RefreshInterval 5 -Endpoint {

                        $Data = Get-InfluxDb -Query 'SELECT * FROM network WHERE time > now() - 5m GROUP BY counter'

                        $ChartData = for($i = 0; $i -lt $data[0].Fields.length; $i++) {
                            $Point = @{}
                            foreach($series in $data) {
                                $Point[$series.counter] = $series.fields[$i].value
                            }
                            $Point
                        }
                        New-UDNivoChart -Stream -Data $ChartData -Id "networkData" -Responsive -MarginBottom 50 -MarginTop 50 -MarginRight 110 -MarginLeft 60 -Keys $Cache:NetworkStats -OffsetType expand -Curve linear  -Colors 'paired'
                    }
                }
            }
        }
    }
} -Port 10001 -Endpoint $Endpoint 