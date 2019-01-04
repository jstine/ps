$Header = @"
<style>
table {
    font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
    border-collapse: collapse;
    width: 100%;
}
th{
    padding-top: 12px;
    padding-bottom: 12px;
    text-align: left;
    background-color: #4CAF50;
    color: white;
}
</style>
"@

$OS = Get-WmiObject -class Win32_OperatingSystem | ConvertTo-HTML -Fragment 
$Bios = Get-WmiObject -Class Win32_BIOS | ConvertTo-HTML -Fragment
$Services = Get-WmiObject -Class Win32_Service | ConvertTo-HTML -Fragment
ConvertTo-HTML -Body "$OS $Bios $Services" -Title "Report" -Head $Header | Out-File StatusReport.html 

