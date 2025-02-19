# Active Directory Devices Report Script

## Overview

This PowerShell script queries Active Directory for computer objects and extracts relevant information, including operating system details, last logon date, account status, and organizational unit (OU) path. The extracted data is then exported to a CSV file for further analysis.

## Features

- Retrieves computer objects from Active Directory.
- Extracts key properties such as OS details, last logon, and password last set.
- Formats the Organizational Unit (OU) path for clarity.
- Exports the collected data to a CSV file.

## Prerequisites

- Windows PowerShell with administrator privileges.
- Active Directory PowerShell module installed.
- Access to an Active Directory environment.

## Installation

1. Ensure that the Active Directory module is installed by running:

   ```powershell
   Get-Module -ListAvailable -Name ActiveDirectory
   ```

   If the module is not available, install the **RSAT: Active Directory** feature.

2. Save the PowerShell script as `AD_Devices_Report.ps1`.

## Usage

1. Open PowerShell as an administrator.
2. Run the script:
   ```powershell
   .\AD_Devices_Report.ps1
   ```
3. The script will query Active Directory, process the data, and generate a CSV file at:
   ```
   C:\AD_Devices_Report.csv
   ```
4. Open the CSV file in Excel or another spreadsheet application for review.

## Output

The exported CSV file includes the following columns:

| Column Name         | Description                            |
| ------------------- | -------------------------------------- |
| **Name**            | Computer name                          |
| **OperatingSystem** | OS installed on the device             |
| **OSVersion**       | Version of the OS                      |
| **OSServicePack**   | Installed service pack (if applicable) |
| **LastLogonDate**   | Last recorded logon date               |
| **DateAdded**       | Date the device was added to AD        |
| **IPv4Address**     | IP address of the device               |
| **Description**     | AD description field                   |
| **PasswordLastSet** | Date of last password change           |
| **AccountEnabled**  | Account status (Enabled/Disabled)      |
| **ManagedBy**       | User or group managing the device      |
| **OUPath**          | Organizational Unit path               |

## Error Handling

- If the Active Directory module is not installed, the script will terminate with an error message.
- If no computer objects are found, an empty CSV file will be generated.

## License

This script is provided under the MIT License. You are free to use and modify it as needed.

## Contributions

Contributions are welcome! Feel free to submit pull requests or report issues.
