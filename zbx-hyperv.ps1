<#
    .EXAMPLE
    .\zbx-hyperv.ps1 lld
    => Retorna JSON para LLD

    .EXAMPLE
    .\zbx-hyperv.ps1 full
    => Retorna JSON com informações detalhadas de cada VM

    .EXAMPLE
    .\zbx-hyperv.ps1 count
    => Retorna JSON com contagem de VMs ligadas, desligadas e total

    .NOTES
    UserParameter=hyperv.lld,powershell -File "C:\Program Files\Zabbix Agent\scripts\zbx-hyperv.ps1" lld
    UserParameter=hyperv.full,powershell -File "C:\Program Files\Zabbix Agent\scripts\zbx-hyperv.ps1" full
    UserParameter=hyperv.count,powershell -File "C:\Program Files\Zabbix Agent\scripts\zbx-hyperv.ps1" count
#>

Param (
    [Parameter(Position=0, Mandatory=$False)]
    [string]$action
)

# Low-Level Discovery function
function Make-LLD {
    try {
        $vms = Get-VM | Select-Object @{Name = "{#VM.NAME}"; Expression = {$_.VMName}},
                                    @{Name = "{#VM.ID}"; Expression = {$_.VMId.Guid}},
                                    @{Name = "{#VM.VERSION}"; Expression = {$_.Version}},
                                    @{Name = "{#VM.CLUSTERED}"; Expression = {[int]$_.IsClustered}},
                                    @{Name = "{#VM.HOST}"; Expression = {$_.ComputerName}},
                                    @{Name = "{#VM.GEN}"; Expression = {$_.Generation}},
                                    @{Name = "{#VM.ISREPLICA}"; Expression = {[int]$_.ReplicationMode}},
                                    @{Name = "{#VM.NOTES}"; Expression = {$_.Notes}}
        return ConvertTo-Json @{"data" = [array]$vms} -Compress
    } catch {
        Write-Host "Error in Make-LLD: $_"
    }
}

# JSON for dependent items
function Get-FullJSON {
    try {
        $to_json = @{}
        
        # Because IntegrationServicesState is string, I've made a dict to map it to int (better for Zabbix):
        # 0 - Up to date
        # 1 - Update required
        # 2 - unknown state
        $integrationSvcState = @{
            "Up to date" = 0
            "Update required" = 1
            "" = 2
        }

        Get-VM | ForEach-Object {
            $vm_data = [psobject]@{
                "State"            = [int]$_.State
                "Uptime"           = [math]::Round($_.Uptime.TotalSeconds)
                "NumaNodes"        = $_.NumaNodesCount
                "NumaSockets"      = $_.NumaSocketCount
                "IntSvcVer"        = [string]$_.IntegrationServicesVersion
                "IntSvcState"      = $integrationSvcState[$_.IntegrationServicesState]
                "CPUUsage"         = $_.CPUUsage
                "ProcessorCount"   = $_.ProcessorCount
                "Memory"           = $_.MemoryAssigned
                "MemoryUsage"      = $_.MemoryDemand
                "ReplMode"         = [int]$_.ReplicationMode
                "ReplState"        = [int]$_.ReplicationState
                "ReplHealth"       = [int]$_.ReplicationHealth
                "StopAction"       = [int]$_.AutomaticStopAction
                "StartAction"      = [int]$_.AutomaticStartAction
                "CritErrAction"    = [int]$_.AutomaticCriticalErrorAction
                "IsClustered"      = [int]$_.IsClustered
                "Disks"            = Get-VHDInfo $_
                "NetworkInterfaces"= Get-NetworkInfo $_
            }
            $to_json += @{$_.VMName = $vm_data}
        }
        return ConvertTo-Json $to_json -Compress
    } catch {
        Write-Host "Error in Get-FullJSON: $_"
    }
}

# Function to get VHD info
function Get-VHDInfo {
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine]$vm
    )
    try {
        $disks = @()
        Get-VMHardDiskDrive -VM $vm | ForEach-Object {
            $disk = Get-VHD -Path $_.Path
            $disks += [psobject]@{
                "Path"     = $_.Path
                "Size"     = $disk.Size
                "FileSize" = $disk.FileSize
            }
        }
        return $disks
    } catch {
        Write-Host "Error in Get-VHDInfo: $_"
    }
}

# Function to get network interface info
function Get-NetworkInfo {
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine]$vm
    )
    try {
        $interfaces = @()
        Get-VMNetworkAdapter -VM $vm | ForEach-Object {
            $interfaces += [psobject]@{
                "Name"       = $_.Name
                "MacAddress" = $_.MacAddress
                "Status"     = $_.Status
                "IPAddresses"= $_.IpAddresses
            }
        }
        return $interfaces
    } catch {
        Write-Host "Error in Get-NetworkInfo: $_"
    }
}

# Function to count VMs
function Count-VMs {
    try {
        $vms       = Get-VM
        $totalVMs  = $vms.Count
        $onlineVMs = ($vms | Where-Object { $_.State -eq 'Running' }).Count
        $offlineVMs = $totalVMs - $onlineVMs
        return ConvertTo-Json @{
            "TotalVMs"   = $totalVMs
            "OnlineVMs"  = $onlineVMs
            "OfflineVMs" = $offlineVMs
        } -Compress
    } catch {
        Write-Host "Error in Count-VMs: $_"
    }
}

# Main switch
switch ($action) {
    "lld" {
        Write-Host (Make-LLD)
    }
    "full" {
        Write-Host (Get-FullJSON)
    }
    "count" {
        Write-Host (Count-VMs)
    }
    Default {
        Write-Host "Syntax error: Use 'lld', 'full' or 'count' as first argument"
    }
}
