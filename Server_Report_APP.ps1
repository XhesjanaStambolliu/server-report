# Krijimi i directory-t ku do të ruhet raporti
$reportPath = "C:\Report"
if (-Not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
}

# Raporti në HTML
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

# Informacioni për procesorët
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

# Informacioni për memorien
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

# Informacioni për sistemin operativ
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

# Informacioni për hapesirën në disk
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

# Informacioni për IIS Application Pools
$html += @"
<h2>IIS Application Pools State</h2>
<table>
    <tr>
        <th>Name</th>
        <th>Status</th>
        <th>CLR Version</th>
        <th>Pipeline Mode</th>
        <th>Start Mode</th>
    </tr>
"@

# Kontrollo nëse IIS është i instaluar
try {
    $objIISAppPool = Get-IISAppPool
    foreach ($objAppPool in $objIISAppPool) {
        if ($objAppPool.State -ne "Started") {
            $html += "<tr style='color:red'>"
        } else {
            $html += "<tr>"
        }
        $html += "<td>" + $objAppPool.Name + "</td><td>" + $objAppPool.State + "</td><td>" + $objAppPool.ManagedRuntimeVersion + "</td><td>" + $objAppPool.ManagedPipelineMode + "</td><td>" + $objAppPool.StartMode + "</td></tr>"
    }
} catch {
    $html += "<tr><td colspan='5'>IIS is not installed or Get-IISAppPool is unavailable.</td></tr>"
}
$html += "</table>"

# Mbyllja e raportit HTML
$html += @"
</body>
</html>
"@

# Merr emrin e kompjuterit
$ComputerName = $env:COMPUTERNAME

# Gjenero datën aktuale në formatin ddMMyyyy
$timestamp = Get-Date -Format "ddMMyyyy"

# Krijo emrin e skedarit duke përfshirë emrin e kompjuterit dhe datën
$Logfile = "$reportPath\${ComputerName}_Report_IIS_$timestamp.html"

# Shkruaj raportin në skedarin HTML
$html | Out-File -FilePath $Logfile -Encoding UTF8

# Hap raportin HTML automatikisht
Start-Process $Logfile
