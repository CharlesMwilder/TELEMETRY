# Define variables
$Clients = Get-ADComputer -Filter * -SearchBase "OU=Paris,DC=billu,DC=com" | Select-Object -ExpandProperty Name
$TelemetryLevel = 1
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
$RegistryKey = "AllowTelemetry"

# Function to disable telemetry services and set telemetry level
function Configure-Telemetry {
    param (
        [string]$ComputerName,
        [int]$Level
    )
    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param ($Level, $RegistryPath, $RegistryKey)
            
            # Disable telemetry-related services
            $services = @("DiagTrack", "dmwappushservice", "diagnosticshub.standardcollector.service")
            foreach ($service in $services) {
                if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                    Stop-Service -Name $service -Force
                    Set-Service -Name $service -StartupType Disabled
                    Write-Output "Service '$service' disabled on $env:COMPUTERNAME."
                } else {
                    Write-Output "Service '$service' not found on $env:COMPUTERNAME."
                }
            }

            # Ensure the registry path exists
            if (-not (Test-Path $RegistryPath)) {
                New-Item -Path $RegistryPath -Force | Out-Null
            }

            # Set the telemetry level
            Set-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value $Level
            Write-Output "Telemetry level set to $Level on $env:COMPUTERNAME."
        } -ArgumentList $Level, $RegistryPath, $RegistryKey
    } catch {
        Write-Error "Failed to configure telemetry on $ComputerName: $_"
    }
}

# Loop through all clients and configure telemetry
foreach ($Client in $Clients) {
    Write-Output "Configuring telemetry on $Client..."
    Configure-Telemetry -ComputerName $Client -Level $TelemetryLevel
}
