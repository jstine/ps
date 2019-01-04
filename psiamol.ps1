#$computers = get-content D:\scripts\computers.txt
get-eventlog -LogName Application -ComputerName . | Out-File .\applicationlog.txt
get-eventlog -LogName Application -ComputerName . -Newest 10 | ConvertTo-Html | Out-File html1.html


# Pull most recent
get-eventlog Application -EntryType Error -Newest 30 | ConvertTo-Html -Fragment | Out-File D:\scripts\applicationerror.html

get-eventlog Security -EntryType Error -Newest 30 | ConvertTo-Html -Fragment | Out-File D:\scripts\applicationerror.html

get-eventlog System -EntryType Error -Newest 30 | ConvertTo-Html -Fragment | Out-File D:\scripts\applicationerror.html
