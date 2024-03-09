$chosen = Read-Host "Choose an already existing sentinel-file"
$chosenF = Split-Path -Path $chosen 
$action = Switch (Read-Host @"
Choose an alarm action:
1 - disconnect USB drives and user
2 - disconnect USB drives, networks and user (requires admin)
3 - shutdown PC
4 - try to restart to BIOS
5 - custom command

Choice
"@) {
    1 { @"
#disconnect USB drive
        `$usbDrives = Get-CimInstance -Class Win32_DiskDrive -Filter 'InterfaceType = "USB"' | 
        Get-CimAssociatedInstance -ResultClassName Win32_DiskPartition | 
        Get-CimAssociatedInstance -ResultClassName Win32_LogicalDisk | 
        ForEach-Object { `$_.DeviceID }
        foreach (`$drive in `$usbDrives) {
            `$driveEject = New-Object -comObject Shell.Application
            `$driveEject.Namespace(17).ParseName(`$drive).InvokeVerb("Eject")
        }
        #disconnect user
        logoff
"@
      }
    2 { @"
#disconnect USB drive
        `$usbDrives = Get-CimInstance -Class Win32_DiskDrive -Filter 'InterfaceType = "USB"' | 
        Get-CimAssociatedInstance -ResultClassName Win32_DiskPartition | 
        Get-CimAssociatedInstance -ResultClassName Win32_LogicalDisk | 
        ForEach-Object { `$_.DeviceID }
        foreach (`$drive in `$usbDrives) {
            `$driveEject = New-Object -comObject Shell.Application
            `$driveEject.Namespace(17).ParseName(`$drive).InvokeVerb("Eject")
        }
        #disconnect networks
        `$activeAdapter = Get-NetAdapter | Where-Object { `$_.Status -eq "Up" }
        if (`$activeAdapter -eq `$null) {
            logoff
        } else {
            foreach (`$NetAdapt in `$activeAdapter) {
                    Disable-NetAdapter -Name `$activeAdapter.Name -Confirm:`$false
            }
        }
        start-sleep 1
        #disconnect user
        logoff
"@
      }
    3 { "shutdown /s /f /t 1 #force quick system shutdown" }
    4 { "shutdown /r /fw /f /t 0 #riavvio al BIOS" }
    5 { Read-Host "Insert command" }
}
$pause = Read-Host "Choose seconds of interval between monitoring activities (default: 10)"
if ($(Test-Path $chosen) -eq $false) {
    Write-Host "`nThe sentinel-file is not present; create it and repeat the procedure. This window will be closed.`n" -ForegroundColor Yellow
    cmd /C pause
    exit
}
if (!$pause) {
    $pause = 10
}
$CanFile = ((Get-Item $chosen | Select-Object LastAccessTime).lastaccesstime).tostring()
$outputF = Read-Host "Choose the path and the name of the monitoring script (.ps1)"
$ErrLog = Read-Host "Choose the path and the name of the error log file (default is: \Desktop\error-log.txt)"
if (!$ErrLog) {
    $ErrLog = "$HOME\Desktop\error-log.txt"
}

New-Item -ItemType File -Path $outputF -Value @"
if ((Test-Path "$($ErrLog)") -eq `$false) {
    New-Item "$($ErrLog)"
}
start-transcript "$($ErrLog)"
while (`$true) {
#interval at startup and between monitoring activities
    Start-Sleep $($pause)
`#check canary presence
    if (`$(Test-Path "$($chosen)") -eq `$false) {
            $action
            break
    } else {
`#check last access
        if ("$($CanFile)" -notmatch `$((Get-Item "$($chosen)" `| `Select-Object `LastAccessTime).lastaccesstime).tostring()) {
                $action
                break
        }
`#check clipboard
        If ((((Get-Clipboard -Format FileDropList).Name) | findstr "$(Split-Path "$($chosen)" -Leaf)") -or (((Get-Clipboard -Format FileDropList).Name | findstr "$($chosenF.split("\")[-1])"))) {
                $action
                break
        }
`#check PowerShell commands history
        If ((Get-Content (Get-PSReadlineOption).HistorySavePath | findstr "$(Split-Path "$($chosen)" -Leaf)") -or (Get-Content (Get-PSReadlineOption).HistorySavePath | findstr "$(Split-Path $chosen)")) { #detect any execution of a PowerShell command that explicitly involves the canary or its folder
                $action
                break
        }
        if (`$Error[0] -ne `$null) {
        stop-transcript
        notepad.exe "$($ErrLog)"
        break
        }
    }
}
stop-transcript
"@ 