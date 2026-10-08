# Version identifier for Grade Monitor shortcut creation tool
$VERSION = "3.0"

# Create COM shell object for creating Windows .lnk shortcuts
$wsh = New-Object -ComObject WScript.Shell
$projectDir = "c:\Users\scott\OneDrive\Documents\Projects\GradeMonitor"
$psPath = Join-Path $projectDir "launch.ps1"
$iconPath = Join-Path $projectDir "app_icon.ico"
$batPath = Join-Path $projectDir "launch.bat"

# Target desktop folders to ensure visibility across standard and OneDrive Desktop setups
$desktopLocations = @(
    [Environment]::GetFolderPath('Desktop'),
    "C:\Users\scott\OneDrive\Desktop",
    $projectDir
) | Select-Object -Unique

foreach ($loc in $desktopLocations) {
    if (Test-Path $loc) {
        # Create .lnk Windows Shortcut pointing directly to hidden PowerShell launcher
        $shortcutFile = Join-Path $loc "Canvas Grade Monitor.lnk"
        $shortcut = $wsh.CreateShortcut($shortcutFile)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File `"$psPath`""
        $shortcut.WorkingDirectory = $projectDir
        $shortcut.Description = "Open Canvas Grade Monitor and sync student grades"
        $shortcut.IconLocation = "$iconPath,0"
        $shortcut.Save()
        Write-Output "Created shortcut: $shortcutFile"

        # Also place batch file for users who prefer double-clicking .bat files
        if ($loc -ne $projectDir) {
            $destBat = Join-Path $loc "Launch Canvas Grade Monitor.bat"
            Copy-Item -Path $batPath -Destination $destBat -Force
            Write-Output "Created batch file: $destBat"
        }
    }
}
