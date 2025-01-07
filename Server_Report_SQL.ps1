#Sql Server Instance: IP 
$SQLInstance = Read-Host "Enter the SQL Server instance"

# Krijimi i directory-t ku do të ruhet raporti
$reportPath = "C:\Report"
if (-Not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
}

# Merr emrin e kompjuterit
$ComputerName = $env:COMPUTERNAME

# Gjenero daten aktuale në formatin ddMMyyyy
$timestamp = Get-Date -Format "ddMMyyyy"

# Krijo emrin e skedarit duke perfshire emrin e kompjuterit dhe daten
$Logfile = "$reportPath\${ComputerName}_Server_Report_SQL_$timestamp.html"

# Raporti ne HTML
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Server Report</title>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table, th, td {
            border: 1px solid black;
        }
        th, td {
            padding: 10px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <h1>Server Report</h1>
"@

# Informacioni per procesoret
$html += @"
<h2>CPU Utilization</h2>
<table>
    <tr>
        <th>Number of Processes</th>
        <th>CPU Load Percentage</th>
        <th>Timestamp</th>
    </tr>
"@

$resultNoOfProcesses = (Get-Process).Count
$resultUtilization = Get-WmiObject Win32_Processor
$time = (Get-Date).ToString('dd/MM/yy HH:mm:ss tt')

$html += "<tr><td>"  + $resultNoOfProcesses + "</td><td>" + $resultUtilization.LoadPercentage + "</td><td>" + $time + "</td></tr>"
$html += "</table>"

# Informacioni per memorien
$html += @"
<h2>Memory Utilization</h2>
<table>
    <tr>
        <th>In Use (GB)</th>
        <th>Available (GB)</th>
        <th>Total (GB)</th>
        <th>In Use Percentage</th>
        <th>Server Uptime</th>
        <th>Timestamp</th>
    </tr>
"@

$Obj = Get-WmiObject -Class WIN32_OperatingSystem
$inUse = [math]::Round(($Obj.TotalVisibleMemorySize - $Obj.FreePhysicalMemory) / 1048576, 2)
$available = [math]::Round($Obj.FreePhysicalMemory / 1048576, 2)
$total = [math]::Round($Obj.TotalVisibleMemorySize / 1048576, 2)
$inUseP = [math]::Round(((($Obj.TotalVisibleMemorySize - $Obj.FreePhysicalMemory) * 100) / $Obj.TotalVisibleMemorySize), 2)

$bootuptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$CurrentDate = Get-Date
$uptime = $CurrentDate - $bootuptime
$serverUp = "{0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

$time = (Get-Date).ToString('dd/MM/yy HH:mm:ss tt')

$html += "<tr><td>"  + $inUse + 
         "</td><td>" + $available + 
         "</td><td>" + $total +
         "</td><td>" + $inUseP +
         "</td><td>" + $serverUp +
         "</td><td>" + $time + "</td></tr>"
$html += "</table>"

# Informacioni per sistemin operativ
$html += @"
<h2>Computer Information</h2>
<table>
    <tr>
        <th>Caption</th>
        <th>Service Pack</th>
        <th>Architecture</th>
        <th>Windows Directory</th>
        <th>Number Of Processes</th>
        <th>Total Visible Memory Size</th>
        <th>Free Physical Memory</th>
        <th>Total Virtual Memory Size</th>
        <th>Free Virtual Memory</th>
        <th>Install Date</th>
        <th>Last BootUp Time</th>
    </tr>
"@

$objOsInfo = Get-WmiObject -Class Win32_OperatingSystem

$html += "<tr><td>" + $objOsInfo.Caption + "</td><td>" + $objOsInfo.ServicePackMajorVersion + "</td><td>" + $objOsInfo.OSArchitecture + "</td><td>" + $objOsInfo.WindowsDirectory + "</td><td>" + (Get-Process).Count + "</td><td>" + [math]::Round($objOsInfo.TotalVisibleMemorySize / 1KB, 2) + " MB</td><td>" + [math]::Round($objOsInfo.FreePhysicalMemory / 1KB, 2) + " MB</td><td>" + [math]::Round($objOsInfo.TotalVirtualMemorySize / 1KB, 2) + " MB</td><td>" + [math]::Round($objOsInfo.FreeVirtualMemory / 1KB, 2) + " MB</td><td>" + $objOsInfo.InstallDate + "</td><td>" + $objOsInfo.LastBootUpTime + "</td></tr>"
$html += "</table>"

# Informacioni per hapesiren ne disk
$html += @"
<h2>Disk Space Information</h2>
<table>
    <tr>
        <th>Drive</th>
        <th>Total Space (GB)</th>
        <th>Free Space (GB)</th>
        <th>Free Space (%)</th>
    </tr>
"@

$disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"

foreach ($disk in $disks) {
    $totalSpace = [math]::Round($disk.Size / 1GB, 2)
    $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
    $freeSpacePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    $html += "<tr><td>" + $disk.DeviceID + "</td><td>" + $totalSpace + "</td><td>" + $freeSpace + "</td><td>" + $freeSpacePercent + "</td></tr>"
}
$html += "</table>"

# Proceset kryesore nga CPU
$html += @"
<h2>Top 10 Processes by CPU</h2>
<table>
    <tr>
        <th>Process Name</th>
        <th>CPU Usage (%)</th>
    </tr>
"@

$topCPUProcesses = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

foreach ($process in $topCPUProcesses) {
    $html += "<tr><td>" + $process.Name + "</td><td>" + $process.CPU + "</td></tr>"
}
$html += "</table>"

# Informacioni per punet e SQL
$html += @"
<h2>SQL Job Information</h2>
<table>
    <tr>
        <th>Name</th>
        <th>Enabled</th>
        <th>Description</th>
        <th>Last Run Date</th>
        <th>Last Run Time</th>
        <th>Next Run Date</th>
        <th>Next Run Time</th>
        <th>Current Execution Status</th>
    </tr>
"@


$jobs = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT 
    j.name,
    j.enabled,
    j.description,
    h.run_date AS last_run_date,
    h.run_time AS last_run_time,
    jh.next_run_date,
    jh.next_run_time,
    h.run_status AS current_execution_status
FROM 
    msdb.dbo.sysjobs j
LEFT JOIN 
    msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
LEFT JOIN 
    msdb.dbo.sysjobschedules jh ON j.job_id = jh.job_id
WHERE 
    h.instance_id IN (
        SELECT MAX(instance_id)
        FROM msdb.dbo.sysjobhistory
        GROUP BY job_id
    )
"@

foreach ($job in $jobs) {
    $html += "<tr><td>" + $job.name + "</td><td>" + $job.enabled + "</td><td>" + $job.description + "</td><td>" + $job.last_run_date + "</td><td>" + $job.last_run_time + "</td><td>" + $job.next_run_date + "</td><td>" + $job.next_run_time + "</td><td>" + $job.current_execution_status + "</td></tr>"
}
$html += "</table>"

# Proceset kryesore sipas perdorimit te memories
$html += @"
<h2>Top 10 Processes by Memory Usage</h2>
<table>
    <tr>
        <th>Process Name</th>
        <th>Memory Usage (MB)</th>
    </tr>
"@

$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 10

foreach ($process in $topMemoryProcesses) {
    $html += "<tr><td>" + $process.Name + "</td><td>" + [math]::Round($process.WorkingSet / 1MB, 2) + "</td></tr>"
}
$html += "</table>"

# Mbyllja e raportit HTML
$html += @"
</body>
</html>
"@

# Gjenero daten aktuale në formatin ddMMyyyy
$timestamp = Get-Date -Format "ddMMyyyy"

# Krijo emrin e skedarit duke perfshire emrin e kompjuterit dhe daten
$Logfile = "$reportPath\${ComputerName}_Server_Report_SQL_$timestamp.html"

# Shkruaj raportin ne skedarin HTML
$html | Out-File -FilePath $Logfile -Encoding UTF8

# Hap raportin HTML automatikisht
Start-Process $Logfile
