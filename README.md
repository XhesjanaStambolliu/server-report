# Server Report PowerShell Scripts

This repository contains two PowerShell scripts for generating server-specific reports.

## Scripts

1. **Server_Report_APP.ps1**
   - Designed for application servers.
   - Collects application logs, memory usage, and service statuses.
   - Run this script on the application server.

2. **Server_Report_SQL.ps1**
   - Designed for SQL servers.
   - Retrieves database metrics like query performance and database sizes.
   - Run this script on the SQL server.

## Usage Instructions

### For Separate Servers
If you have separate servers for application and SQL services:
- Run **Server_Report_APP.ps1** on the application server.
- Run **Server_Report_SQL.ps1** on the SQL server.

### Steps to Execute
1. Transfer the script to the appropriate server.
2. Open PowerShell as an administrator.
3. Navigate to the script directory.
4. Run the script using:
   ```powershell
   .\Server_Report_APP.ps1   # For the application server
   .\Server_Report_SQL.ps1   # For the SQL server
