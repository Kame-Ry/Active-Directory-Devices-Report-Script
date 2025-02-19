# Define the output file path
$outputFile = "C:\AD_Devices_Report.csv"

# Import the Active Directory module
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "The Active Directory module is not available on this system."
    exit
}
Import-Module ActiveDirectory

# Query all computer objects from Active Directory
Write-Host "Querying Active Directory for computer objects..."
$computers = Get-ADComputer -Filter * -Property OperatingSystem, OperatingSystemVersion, OperatingSystemServicePack, LastLogonDate, WhenCreated, DistinguishedName, IPv4Address, Description, PasswordLastSet, Enabled, ManagedBy

# Collect and process the data
Write-Host "Processing computer objects..."
$computerData = $computers | ForEach-Object {
    # Extract the OU path from DistinguishedName
    $ouPath = ($_.DistinguishedName -split ',CN=Computers,?')[0] -replace '^CN=.*?,OU=', 'OU='

    [PSCustomObject]@{
        Name                     = $_.Name
        OperatingSystem          = $_.OperatingSystem
        OSVersion                = $_.OperatingSystemVersion
        OSServicePack            = $_.OperatingSystemServicePack
        LastLogonDate            = if ($_.LastLogonDate) { $_.LastLogonDate } else { "Never" }
        DateAdded                = $_.WhenCreated
        IPv4Address              = $_.IPv4Address
        Description              = $_.Description
        PasswordLastSet          = $_.PasswordLastSet
        AccountEnabled           = if ($_.Enabled) { "Enabled" } else { "Disabled" }
        ManagedBy                = $_.ManagedBy
        OUPath                   = $ouPath
    }
}

# Export the data to CSV
Write-Host "Exporting data to CSV file: $outputFile"
$computerData | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Export complete. The report is available at: $outputFile"
