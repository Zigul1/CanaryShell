$chosen = Read-Host "Scegli un file-sentinella già esistente"
$chosenF = Split-Path -Path $chosen 
$action = Switch (Read-Host @"
Scegli l'azione da eseguire come allarme:
1 - disconnessione USB drive e utente
2 - disconnessione USB drive, rete e utente (richiede admin)
3 - spegnimento pc
4 - tentativo di riavvio al BIOS
5 - comando personalizzato

Scelta
"@) {
    1 { @"
#disconnessione USB drive
        `$usbDrives = Get-CimInstance -Class Win32_DiskDrive -Filter 'InterfaceType = "USB"' | 
        Get-CimAssociatedInstance -ResultClassName Win32_DiskPartition | 
        Get-CimAssociatedInstance -ResultClassName Win32_LogicalDisk | 
        ForEach-Object { `$_.DeviceID }
        foreach (`$drive in `$usbDrives) {
            `$driveEject = New-Object -comObject Shell.Application
            `$driveEject.Namespace(17).ParseName(`$drive).InvokeVerb("Eject")
        }
        #disconnessione utente
        logoff
"@
      }
    2 { @"
#disconnessione USB drive
        `$usbDrives = Get-CimInstance -Class Win32_DiskDrive -Filter 'InterfaceType = "USB"' | 
        Get-CimAssociatedInstance -ResultClassName Win32_DiskPartition | 
        Get-CimAssociatedInstance -ResultClassName Win32_LogicalDisk | 
        ForEach-Object { `$_.DeviceID }
        foreach (`$drive in `$usbDrives) {
            `$driveEject = New-Object -comObject Shell.Application
            `$driveEject.Namespace(17).ParseName(`$drive).InvokeVerb("Eject")
        }
        #disconnessione rete
        `$activeAdapter = Get-NetAdapter | Where-Object { `$_.Status -eq "Up" }
        if (`$activeAdapter -eq `$null) {
            logoff
        } else {
            foreach (`$NetAdapt in `$activeAdapter) {
                    Disable-NetAdapter -Name `$activeAdapter.Name -Confirm:`$false
            }
        }
        start-sleep 1
        #disconnessione utente
        logoff
"@
      }
    3 { "shutdown /s /f /t 1 #rapido arresto forzato sistema" }
    4 { "shutdown /r /fw /f /t 0 #riavvio al BIOS" }
    5 { Read-Host "Inserire comando" }
}
$pausa = Read-Host "Scegli i secondi di intervallo fra i monitoraggi (default: 10)"
if ($(Test-Path $chosen) -eq $false) {
    Write-Host "`nIl file-sentinella non è presente; crearlo e ripetere la procedura. Questa finestra verrà chiusa.`n" -ForegroundColor Yellow
    cmd /C pause
    exit
}
if (!$pausa) {
    $pausa = 10
}
$CanFile = ((Get-Item $chosen | Select-Object LastAccessTime).lastaccesstime).tostring()
$outputF = Read-Host "Scegli il percorso e il nome dello script (.ps1) di monitoraggio"

New-Item -ItemType File -Path $outputF -Value @"
while (`$true) {
#intervallo all'avvio e fra i monitoraggi
    Start-Sleep $($pausa)
`#controllo presenza canary
    if (`$(Test-Path $chosen) -eq `$false) {
            $action
            break
    } else {
`#controllo ultimo accesso
        if ("$($CanFile)" -notmatch `$((Get-Item $chosen `| `Select-Object `LastAccessTime).lastaccesstime).tostring()) {
                $action
                break
        }
`#controllo clipboard
        If ((((Get-Clipboard -Format FileDropList).Name) | findstr "$(Split-Path $chosen -Leaf)") -or (((Get-Clipboard -Format FileDropList).Name | findstr "$($chosenF.split("\")[-1])"))) {
                $action
                break
        }
`#controllo storia comandi PowerShell
        If ((Get-Content (Get-PSReadlineOption).HistorySavePath | findstr "$(Split-Path $chosen -Leaf)") -or (Get-Content (Get-PSReadlineOption).HistorySavePath | findstr "$(Split-Path $chosen)")) { #rileva esecuzione di qualunqe comando PowerShell coinvolga esplicitamente il canary o la sua cartella
                $action
                break
        }
    }
}
"@ 