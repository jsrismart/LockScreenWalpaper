<#
.SYNOPSIS
    Enforce Lock Screen & Logon Screen Wallpaper (Windows 10/11 Pro)
 
.DESCRIPTION
    - Forces wallpaper immediately.
    - Persists via scheduled task (runs at startup).
    - Blocks user personalization.
#>

$WallpaperPath = "C:\ProgramData\FleetMDM\Wallpaper\Fleet_LockScreen.png"   # <-- Change this
 
# ==== 1. Validate ====
if (!(Test-Path $WallpaperPath)) {
    Write-Output "Wallpaper not found at $WallpaperPath"
    exit 1
}
 
# ==== 2. Enforce Logon Screen Background ====
Write-Output "Enforcing logon screen background..."
$SystemRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (!(Test-Path $SystemRegPath)) {
    New-Item -Path $SystemRegPath -Force | Out-Null
}
# 0 = enable background image
Set-ItemProperty -Path $SystemRegPath -Name "DisableLogonBackgroundImage" -Value 0 -Type DWord
Write-Output "Logon background enabled."

# ==== 3. Block User Personalization of Lock Screen ====
Write-Output "Blocking lock screen personalization..."
$UserRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
if (!(Test-Path $UserRegPath)) {
    New-Item -Path $UserRegPath -Force | Out-Null
}

Set-ItemProperty -Path $UserRegPath -Name "NoDispScrSavPage" -Value 1 -Type DWord
Write-Output "User personalization disabled."

# ==== 4. Apply Lock Screen Immediately ====
Write-Output "Forcing lock screen wallpaper now..."
$CSPPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
if (!(Test-Path $CSPPath)) {
    New-Item -Path $CSPPath -Force | Out-Null
}

Set-ItemProperty -Path $CSPPath -Name "LockScreenImagePath" -Value $WallpaperPath -Type String
Set-ItemProperty -Path $CSPPath -Name "LockScreenImageStatus" -Value 1 -Type DWord
Set-ItemProperty -Path $CSPPath -Name "LockScreenImageUrl" -Value $WallpaperPath -Type String
Write-Output "Lock screen wallpaper applied immediately."

# ==== 5. Scheduled Task for Persistence ====
Write-Output "Creating scheduled task to re-apply at startup..."
 
$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -Command `"Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP' -Name LockScreenImagePath -Value '$WallpaperPath' -Type String; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP' -Name LockScreenImageStatus -Value 1 -Type DWord; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP' -Name LockScreenImageUrl -Value '$WallpaperPath' -Type String`""
 
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal
 
Register-ScheduledTask -TaskName "EnforceLockScreenWallpaper" -InputObject $Task -Force
 
Write-Output "Scheduled task created."

# ==== 6. Force Refresh Now ====
gpupdate /force | Out-Null
Write-Output "Done! Lock screen & logon wallpaper enforced immediately and will persist after reboot."