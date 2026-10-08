@echo off
rem =========================================================================
rem Canvas Grade Monitor Server Stop Utility
rem Version: 3.0
rem Stops running background Node.js server instances associated with Grade Monitor
rem =========================================================================

set VERSION=3.0
echo Stopping Canvas Grade Monitor local server on port 3000...

powershell -Command "$conns = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue; foreach ($c in $conns) { $proc = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue; if ($proc -and $proc.ProcessName -like '*node*') { Stop-Process -Id $proc.Id -Force; Write-Output ('Stopped server PID ' + $proc.Id) } }"

echo Server stopped.
