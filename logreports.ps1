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

$bodystyle = @"
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

$applog = get-eventlog Application -EntryType Error -Newest 30 | ConvertTo-Html -Body $bodystyle

$seclog = get-eventlog Security -EntryType FailureAudit -Newest 30 | ConvertTo-Html -Fragment -Body $bodystyle

$syslog = get-eventlog System  -Newest 30 | ConvertTo-Html -Fragment -Body $bodystyle

ConvertTo-HTML -Body "$applog $seclog $syslog" -Title "Report" -Head $Header | Out-File logReport.html 
