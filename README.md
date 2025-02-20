# Active Directory Devices Report Script

## Overview
This PowerShell script queries Active Directory for computer objects and extracts relevant information—including operating system details, last logon date, account status, and the organizational unit (OU) path. The script first attempts to use the Active Directory module. If that module is not available (or if the AD query fails), it automatically falls back to using .NET’s `DirectoryEntry/DirectorySearcher` to perform LDAP queries. Additionally, a log file is generated to record each step of the process, aiding in troubleshooting and tracking the script's execution.

## Features

- **Dual Query Methods**  
  Attempts to use the Active Directory module first; if not available or if the query fails, it falls back to `DirectoryEntry/DirectorySearcher`.

- **LDAP Mode Support**  
  Supports LDAP mode via the `-UseLDAP` switch. In this mode, the script can prompt for a domain name, auto-discover a Domain Controller (DC) using a DNS SRV lookup, or ask for manual input if discovery fails.

- **Credential Prompting**  
  If domain admin credentials are not supplied, the script prompts the user for them.

- **Detailed Logging**  
  Generates a log file alongside the CSV output that records each significant step and any errors encountered during execution.

- **CSV Export**  
  Exports the collected data to a CSV file for further analysis.

## Prerequisites

- Windows PowerShell running with administrator privileges.
- (Optional) Active Directory PowerShell module.
  - *Note:* If the AD module is not installed, the script automatically uses `DirectoryEntry/DirectorySearcher` without attempting to install the module.
- Access to an Active Directory environment.

## Installation

(Optional) To use the AD module, ensure it is installed by running:

```powershell
Get-Module -ListAvailable -Name ActiveDirectory
```

If the module is not available, the script will fall back to `DirectoryEntry/DirectorySearcher`.

Save the script as `AD_Devices_Report.ps1`.

## Usage

Open PowerShell as an administrator and run the script:

```powershell
.\AD_Devices_Report.ps1
```

To force LDAP mode (ideal for non-domain joined devices), run:

```powershell
.\AD_Devices_Report.ps1 -UseLDAP
```

Optionally, specify a Domain Controller and/or credentials:

```powershell
.\AD_Devices_Report.ps1 -UseLDAP -DC "dc.example.com" -Credential (Get-Credential)
```

The script will then:
1. Query Active Directory for computer objects.
2. Process the data and extract key properties.
3. Generate a CSV file at: `C:\AD_Devices_Report.csv`
4. Generate a log file at: `C:\AD_Devices_Report_Log.txt`

Open the CSV file in Excel or your preferred spreadsheet application for review.

## Output

The exported CSV file includes the following columns:

| Column Name          | Description                           |
|----------------------|---------------------------------------|
| Name                | Computer name                         |
| OperatingSystem     | OS installed on the device           |
| OSVersion          | Version of the OS                     |
| OSServicePack      | Installed service pack (if applicable) |
| LastLogonDate      | Last recorded logon date              |
| DateAdded          | Date the device was added to AD       |
| IPv4Address        | IP address of the device              |
| Description        | AD description field                  |
| PasswordLastSet    | Date of last password change          |
| AccountEnabled     | Account status (Enabled/Disabled)     |
| ManagedBy          | User or group managing the device     |
| OUPath            | Organizational Unit path              |

## Logging

- A log file (`C:\AD_Devices_Report_Log.txt`) is created in the same directory as the CSV output.
- The log records every major step and error encountered, making it easier to troubleshoot and understand the script's execution flow.

## Error Handling

- If the Active Directory module is not found or the AD module query fails, the script falls back to `DirectoryEntry/DirectorySearcher`.
- If no computer objects are found, an empty CSV file will be generated.
- All errors and key steps are logged to the log file for review.

## License

This script is provided under the MIT License. You are free to use and modify it as needed.

## Contributions

Contributions are welcome! Feel free to submit pull requests or report issues.
