<#    
.PARAMETER UseLDAP
    Switch to force LDAP mode regardless of the machine's domain join status.
.PARAMETER DC
    (Optional) The Domain Controller’s FQDN or IP address.
    If not provided, the script will attempt discovery or ask for manual input.
.PARAMETER Credential
    (Optional) Credentials for LDAP binding.
    If not provided, you’ll be prompted to enter them.
#>

param(
    [switch]$UseLDAP,
    [string]$DC,
    [PSCredential]$Credential
)

# Define the output file paths for CSV and log file.
$outputFile = "C:\AD_Devices_Report.csv"
$logFile = "C:\AD_Devices_Report_Log.txt"

# Clear any existing log file.
if (Test-Path $logFile) { Remove-Item $logFile }

# Function to write messages to both the console and the log file.
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

Write-Log "Script started."

# Check if the Active Directory module is available.
$adModuleAvailable = $true
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "Active Directory module is not available. Will use DirectorySearcher as fallback."
    $adModuleAvailable = $false
}
else {
    Write-Log "Active Directory module found."
    Import-Module ActiveDirectory
    Write-Log "Active Directory module imported."
}

# Determine if the machine is domain joined.
$domainJoined = $false
try {
    [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() | Out-Null
    $domainJoined = $true
    Write-Log "Machine is domain joined."
}
catch {
    $domainJoined = $false
    Write-Log "Machine is not domain joined."
}

$computers = $null
$usingADModule = $false

# Attempt query using the AD module if available.
if ($adModuleAvailable) {
    try {
        if ($UseLDAP -or -not $domainJoined) {
            Write-Log "Running in LDAP mode using the AD module."
            if (-not $DC) {
                $domainName = Read-Host "Enter the domain name (e.g., example.com) to locate the Domain Controller"
                Write-Log "User entered domain name: $domainName"
                try {
                    $srvRecords = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$domainName" -Type SRV -ErrorAction Stop
                    $firstRecord = $srvRecords | Where-Object { $_.NameTarget } | Select-Object -First 1
                    if ($firstRecord) {
                        $DC = $firstRecord.NameTarget
                        Write-Log "Found Domain Controller via DNS: $DC"
                    }
                    else {
                        Write-Log "DNS lookup did not return a Domain Controller for '$domainName'."
                        $DC = Read-Host "Please manually enter the Domain Controller FQDN or IP address"
                        Write-Log "User entered DC: $DC"
                    }
                }
                catch {
                    Write-Log "DNS lookup failed for '$domainName'."
                    $DC = Read-Host "Please manually enter the Domain Controller FQDN or IP address"
                    Write-Log "User entered DC: $DC"
                }
            }
            if (-not $Credential) {
                $Credential = Get-Credential -Message "Enter your Domain Admin credentials"
                Write-Log "User entered domain admin credentials."
            }
            Write-Log "Using LDAP mode. Connecting to DC: $DC"
            $computers = Get-ADComputer -Server $DC -Credential $Credential -Filter * `
                -Property OperatingSystem, OperatingSystemVersion, OperatingSystemServicePack, LastLogonDate, WhenCreated, DistinguishedName, IPv4Address, Description, PasswordLastSet, Enabled, ManagedBy
        }
        else {
            Write-Log "Machine is domain joined. Querying Active Directory locally using the AD module."
            $computers = Get-ADComputer -Filter * `
                -Property OperatingSystem, OperatingSystemVersion, OperatingSystemServicePack, LastLogonDate, WhenCreated, DistinguishedName, IPv4Address, Description, PasswordLastSet, Enabled, ManagedBy
        }
        $usingADModule = $true
        Write-Log "AD module query succeeded."
    }
    catch {
        Write-Log "AD module query failed: $($_.Exception.Message)"
        $usingADModule = $false
    }
}

# If the AD module wasn't used or the query failed, fall back to DirectoryEntry/DirectorySearcher.
if (-not $usingADModule -or -not $computers) {
    Write-Log "Falling back to DirectoryEntry/DirectorySearcher method."
    
    if ($UseLDAP -or -not $domainJoined) {
        if (-not $DC) {
            $domainName = Read-Host "Enter the domain name (e.g., example.com) to locate the Domain Controller"
            Write-Log "User entered domain name: $domainName"
            try {
                $srvRecords = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$domainName" -Type SRV -ErrorAction Stop
                $firstRecord = $srvRecords | Where-Object { $_.NameTarget } | Select-Object -First 1
                if ($firstRecord) {
                    $DC = $firstRecord.NameTarget
                    Write-Log "Found Domain Controller via DNS: $DC"
                }
                else {
                    Write-Log "DNS lookup did not return a Domain Controller for '$domainName'."
                    $DC = Read-Host "Please manually enter the Domain Controller FQDN or IP address"
                    Write-Log "User entered DC: $DC"
                }
            }
            catch {
                Write-Log "DNS lookup failed for '$domainName'."
                $DC = Read-Host "Please manually enter the Domain Controller FQDN or IP address"
                Write-Log "User entered DC: $DC"
            }
        }
        if (-not $Credential) {
            $Credential = Get-Credential -Message "Enter your Domain Admin credentials"
            Write-Log "User entered domain admin credentials."
        }
        $ldapPath = "LDAP://$DC"
        $username = $Credential.UserName
        $password = $Credential.GetNetworkCredential().Password
        Write-Log "Binding to LDAP path: $ldapPath using provided credentials."
        $rootEntry = New-Object System.DirectoryServices.DirectoryEntry($ldapPath, $username, $password)
    }
    else {
        Write-Log "Machine is domain joined. Using current credentials to bind to RootDSE."
        $rootDSE = New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
        $defaultNamingContext = $rootDSE.Properties["defaultNamingContext"][0]
        $ldapPath = "LDAP://$defaultNamingContext"
        Write-Log "Default naming context: $defaultNamingContext"
        $rootEntry = New-Object System.DirectoryServices.DirectoryEntry($ldapPath)
    }
    
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = $rootEntry
    $searcher.Filter = "(&(objectCategory=computer))"
    $searcher.PageSize = 1000
    Write-Log "DirectorySearcher created with filter for computer objects."
    
    $properties = @(
        "name",
        "operatingSystem",
        "operatingSystemVersion",
        "operatingSystemServicePack",
        "lastLogonTimestamp",
        "whenCreated",
        "distinguishedName",
        "dNSHostName",
        "description",
        "pwdLastSet",
        "userAccountControl",
        "managedBy"
    )
    $searcher.PropertiesToLoad.Clear()
    $properties | ForEach-Object { $searcher.PropertiesToLoad.Add($_) | Out-Null }
    Write-Log "Properties to load: $($properties -join ', ')"
    
    try {
        $results = $searcher.FindAll()
        Write-Log "DirectorySearcher query executed. Found $($results.Count) computer objects."
    }
    catch {
        Write-Log "DirectorySearcher query failed: $($_.Exception.Message)"
        exit
    }
    
    $computers = foreach ($result in $results) {
        $props = $result.Properties
        [PSCustomObject]@{
            Name            = if ($props["name"]) { $props["name"][0] } else { "" }
            OperatingSystem = if ($props["operatingSystem"]) { $props["operatingSystem"][0] } else { "" }
            OSVersion       = if ($props["operatingSystemVersion"]) { $props["operatingSystemVersion"][0] } else { "" }
            OSServicePack   = if ($props["operatingSystemServicePack"]) { $props["operatingSystemServicePack"][0] } else { "" }
            LastLogonDate   = if ($props["lastLogonTimestamp"]) {
                                  try { [DateTime]::FromFileTime($props["lastLogonTimestamp"][0]) }
                                  catch { "Invalid timestamp" }
                              } else { "Never" }
            DateAdded       = if ($props["whenCreated"]) { $props["whenCreated"][0] } else { "" }
            IPv4Address     = if ($props["dNSHostName"]) { $props["dNSHostName"][0] } else { "" }
            Description     = if ($props["description"]) { $props["description"][0] } else { "" }
            PasswordLastSet = if ($props["pwdLastSet"]) {
                                  try { [DateTime]::FromFileTime($props["pwdLastSet"][0]) }
                                  catch { "" }
                              } else { "" }
            AccountEnabled  = if ($props["userAccountControl"]) {
                                  $uac = $props["userAccountControl"][0]
                                  if ($uac -band 2) { "Disabled" } else { "Enabled" }
                              } else { "Enabled" }
            ManagedBy       = if ($props["managedBy"]) { $props["managedBy"][0] } else { "" }
            OUPath          = if ($props["distinguishedName"]) {
                                  $dn = $props["distinguishedName"][0]
                                  if ($dn -match ",OU=") { ($dn -split ',CN=Computers,?')[0] -replace '^CN=.*?,OU=', 'OU=' } else { "N/A" }
                              } else { "N/A" }
        }
    }
    Write-Log "DirectorySearcher fallback processing completed."
}

Write-Log "Processing complete. Exporting data to CSV file: $outputFile"
$computers | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Log "CSV export complete. Report available at: $outputFile"
Write-Log "Script finished."
