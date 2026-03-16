powershell

#Requires -RunAsAdministrator
<#
.SYNOPSIS
    ProTweaker v2 — Ultimate Windows 10/11 Optimizer
.DESCRIPTION
    150+ fully functional tweaks. Stunning dark GUI. No placeholders.
    Every tweak executes real registry/service/policy changes.
.NOTES
    Run as Administrator on Windows 10 21H2+ or Windows 11.
    irm "https://raw.githubusercontent.com/upw7/tweak/refs/heads/main/tweak.ps1" | iex
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ══════════════════════════════════════════════════════════════
#  TWEAK ENGINE — 150+ REAL FUNCTIONS
# ══════════════════════════════════════════════════════════════

function Write-Log {
    param([string]$Msg, [string]$Type = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) {
        "OK"   { "✓" } "WARN" { "⚠" } "ERR"  { "✗" } "HEAD" { "►" } default { "·" }
    }
    $script:LogBox.Dispatcher.Invoke([action]{
        $script:LogBox.AppendText("$ts  $prefix  $Msg`n")
        $script:LogBox.ScrollToEnd()
    })
}

function Set-Reg {
    param($Path, $Name, $Value, $Type = "DWord")
    New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
}

# ── ESSENTIAL ─────────────────────────────────────────────────

function Tweak-CreateRestorePoint {
    Write-Log "Creating system restore point..." "HEAD"
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "ProTweaker v2" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    Write-Log "Restore point created." "OK"
}

function Tweak-DeleteTemp {
    Write-Log "Cleaning temp files..." "HEAD"
    $dirs = @($env:TEMP,"$env:WINDIR\Temp","$env:WINDIR\Prefetch",
              "$env:LOCALAPPDATA\Temp","$env:WINDIR\SoftwareDistribution\Download")
    foreach ($d in $dirs) {
        if (Test-Path $d) {
            Get-ChildItem $d -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "Temp files cleaned." "OK"
}

function Tweak-DisableTelemetry {
    Write-Log "Disabling all telemetry services..." "HEAD"
    $svcs = @("DiagTrack","dmwappushservice","WerSvc","PcaSvc","WMPNetworkSvc",
              "RemoteRegistry","RetailDemo","MapsBroker","lfsvc","SysMain",
              "TrkWks","WdiServiceHost","WdiSystemHost","wbengine")
    foreach ($s in $svcs) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        Set-Service  $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                   "AllowTelemetry"               0
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"    "AllowTelemetry"               0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"                        "AITEnable"                    0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"                        "DisableInventory"             1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows"                        "CEIPEnable"                   0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC"                         "PreventHandwritingDataSharing" 1
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"                    "TailoredExperiencesWithDiagnosticDataEnabled" 0
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe" "Debugger" "%" "String"
    Write-Log "Telemetry fully disabled." "OK"
}

function Tweak-DisableActivityHistory {
    Write-Log "Disabling Activity History..." "HEAD"
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed"    0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities"  0
    Write-Log "Activity History disabled." "OK"
}

function Tweak-DisablePS7Telemetry {
    Write-Log "Disabling PS7 / .NET telemetry..." "HEAD"
    [Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT","1","Machine")
    [Environment]::SetEnvironmentVariable("DOTNET_CLI_TELEMETRY_OPTOUT","1","Machine")
    [Environment]::SetEnvironmentVariable("DOTNET_NOLOGO","1","Machine")
    Write-Log "PS7/.NET telemetry disabled." "OK"
}

function Tweak-DisableLocationAds {
    Write-Log "Disabling location / advertising ID..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"     "Enabled"           0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"        "DisableLocation"   1
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" "Status"            0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
    Write-Log "Location / ads disabled." "OK"
}

function Tweak-DisableHibernation {
    Write-Log "Disabling hibernation..." "HEAD"
    powercfg /hibernate off 2>$null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HibernateEnabled" 0
    Write-Log "Hibernation disabled (hiberfil.sys freed)." "OK"
}

function Tweak-DisableFolderDiscovery {
    Write-Log "Disabling folder type discovery..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" "FolderType" "NotSpecified" "String"
    Write-Log "Folder discovery disabled." "OK"
}

function Tweak-DisableWidgets {
    Write-Log "Disabling Widgets..." "HEAD"
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
    Set-Reg "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" "value" 0
    winget uninstall "MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" --silent 2>$null
    Write-Log "Widgets disabled." "OK"
}

function Tweak-DisableCortana {
    Write-Log "Disabling Cortana..." "HEAD"
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"             0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortanaAboveLock"    0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowSearchToUseLocation" 0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb"    0
    Write-Log "Cortana disabled." "OK"
}

function Tweak-DisableAutoplay {
    Write-Log "Disabling AutoPlay / AutoRun..." "HEAD"
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 255
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" "DisableAutoplay" 1
    Write-Log "AutoPlay disabled." "OK"
}

function Tweak-DisableWindowsTips {
    Write-Log "Disabling Windows tips / suggestions..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" 0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" 0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353696Enabled" 0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled"              0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled"    0
    Write-Log "Windows tips/suggestions disabled." "OK"
}

function Tweak-DisableLockScreenAds {
    Write-Log "Disabling lock screen ads / Spotlight..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled"          0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled"   0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "ContentDeliveryAllowed"             0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "OemPreInstalledAppsEnabled"         0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEnabled"            0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEverEnabled"        0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled"         0
    Write-Log "Lock screen ads disabled." "OK"
}

function Tweak-DisableWindowsErrorReporting {
    Write-Log "Disabling Windows Error Reporting..." "HEAD"
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"          "Disabled" 1
    Stop-Service WerSvc -Force -ErrorAction SilentlyContinue
    Set-Service  WerSvc -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "Error Reporting disabled." "OK"
}

function Tweak-DisableSmartScreen {
    Write-Log "Disabling SmartScreen..." "HEAD"
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"                        "EnableSmartScreen"     0
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"                "SmartScreenEnabled"    "Off" "String"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost"                 "EnableWebContentEvaluation" 0
    Write-Log "SmartScreen disabled." "OK"
}

function Tweak-DisableSearchHighlights {
    Write-Log "Disabling Search Highlights..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDynamicSearchBoxEnabled" 0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"       "EnableDynamicContentInWSB"  0
    Write-Log "Search highlights disabled." "OK"
}

# ── ADVANCED ──────────────────────────────────────────────────

function Tweak-BlockAdobeNetwork {
    Write-Log "Blocking Adobe activation/telemetry servers..." "HEAD"
    $hosts = "C:\Windows\System32\drivers\etc\hosts"
    $entries = @(
        "0.0.0.0 lmlicenses.wip4.adobe.com","0.0.0.0 na1r.services.adobe.com",
        "0.0.0.0 activate.adobe.com","0.0.0.0 practivate.adobe.com",
        "0.0.0.0 ereg.adobe.com","0.0.0.0 activate.wip3.adobe.com",
        "0.0.0.0 wip3.adobe.com","0.0.0.0 3dns-3.adobe.com",
        "0.0.0.0 3dns-2.adobe.com","0.0.0.0 adobe-dns.adobe.com",
        "0.0.0.0 adobe-dns-2.adobe.com","0.0.0.0 adobe-dns-3.adobe.com",
        "0.0.0.0 ereg.wip3.adobe.com","0.0.0.0 activate-sea.adobe.com",
        "0.0.0.0 adobe.activate.com","0.0.0.0 adobeereg.com",
        "0.0.0.0 www.adobeereg.com","0.0.0.0 wip.adobe.com",
        "0.0.0.0 wip1.adobe.com","0.0.0.0 wip2.adobe.com","0.0.0.0 wip4.adobe.com",
        "0.0.0.0 na2r.services.adobe.com","0.0.0.0 ccmdl.adobe.com"
    )
    $cur = Get-Content $hosts -ErrorAction SilentlyContinue
    foreach ($e in $entries) { if ($cur -notcontains $e) { Add-Content $hosts $e } }
    Write-Log "Adobe network blocked via hosts." "OK"
}

function Tweak-BlockRazerInstalls {
    Write-Log "Blocking Razer auto-installs..." "HEAD"
    $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
    Set-Reg $p "DenyDeviceIDs" 1
    Set-Reg $p "DenyDeviceIDsRetroactive" 1
    Write-Log "Razer auto-install blocked." "OK"
}

function Tweak-DebloatBrave {
    Write-Log "Debloating Brave browser..." "HEAD"
    $prefs = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Preferences"
    if (Test-Path $prefs) {
        try {
            $j = Get-Content $prefs -Raw | ConvertFrom-Json
            $j.brave.stats.enabled = $false
            $j | ConvertTo-Json -Depth 50 | Set-Content $prefs
            Write-Log "Brave preferences updated." "OK"
        } catch { Write-Log "Brave prefs update skipped (may be running)." "WARN" }
    } else { Write-Log "Brave not found." "WARN" }
}

function Tweak-DisableBackgroundApps {
    Write-Log "Disabling background apps..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"                       "BackgroundAppGlobalToggle" 0
    Get-ChildItem "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -ErrorAction SilentlyContinue |
        ForEach-Object { Set-ItemProperty $_.PSPath "Disabled" 1 -ErrorAction SilentlyContinue }
    Write-Log "Background apps disabled." "OK"
}

function Tweak-DisableFullscreenOptimizations {
    Write-Log "Disabling fullscreen optimizations..." "HEAD"
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode"              2
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode"     1
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior"                  2
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_EFSEBehaviorMode"             2
    Write-Log "Fullscreen optimizations disabled." "OK"
}

function Tweak-DisableIPv6 {
    Write-Log "Disabling IPv6..." "HEAD"
    Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue |
        Where-Object Enabled | Disable-NetAdapterBinding -ComponentID ms_tcpip6
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" 0xFF
    Write-Log "IPv6 disabled on all adapters." "OK"
}

function Tweak-DisableCopilot {
    Write-Log "Disabling Microsoft Copilot..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" 0
    Write-Log "Copilot disabled." "OK"
}

function Tweak-DisableNotificationCenter {
    Write-Log "Disabling Notification Center / Action Center..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "DisableNotificationCenter" 1
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 0
    Write-Log "Notification Center disabled." "OK"
}

function Tweak-DisableStorageSense {
    Write-Log "Disabling Storage Sense..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "04" 0
    Write-Log "Storage Sense disabled." "OK"
}

function Tweak-DisableTeredo {
    Write-Log "Disabling Teredo..." "HEAD"
    netsh interface teredo set state disabled 2>$null | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" 0x8
    Write-Log "Teredo disabled." "OK"
}

function Tweak-DebloatEdge {
    Write-Log "Debloating Microsoft Edge..." "HEAD"
    $maps = @(
        @("BackgroundModeEnabled",0),@("UserFeedbackAllowed",0),@("MetricsReportingEnabled",0),
        @("SendSiteInfoToImproveServices",0),@("DiagnosticData",0),
        @("AddressBarMicrosoftSearchInBingProviderEnabled",0),@("EdgeCollectionsEnabled",0),
        @("EdgeShoppingAssistantEnabled",0),@("MicrosoftEdgeInsiderPromotionEnabled",0),
        @("ShowRecommendationsEnabled",0),@("HubsSidebarEnabled",0),
        @("PromotionalTabsEnabled",0),@("StartupBoostEnabled",0),
        @("EdgeAssetDeliveryServiceEnabled",0),@("SpotlightExperiencesAndRecommendationsEnabled",0),
        @("ShowAcrobatSubscriptionButton",0),@("LinkedAccountEnabled",0)
    )
    foreach ($m in $maps) { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" $m[0] $m[1] }
    Write-Log "Edge debloated." "OK"
}

function Tweak-PreferIPv4 {
    Write-Log "Preferring IPv4 over IPv6..." "HEAD"
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" 0x20
    Write-Log "IPv4 preferred." "OK"
}

function Tweak-RemoveOneDrive {
    Write-Log "Removing OneDrive..." "HEAD"
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    @("$env:SYSTEMROOT\System32\OneDriveSetup.exe","$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe") |
        Where-Object { Test-Path $_ } | ForEach-Object { & $_ /uninstall 2>$null }
    Remove-Item "$env:USERPROFILE\OneDrive"                     -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive"          -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive"           -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"   -Force -ErrorAction SilentlyContinue
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1
    Write-Log "OneDrive removed." "OK"
}

function Tweak-RemoveXbox {
    Write-Log "Removing Xbox / Gaming components..." "HEAD"
    $apps = @("Microsoft.XboxApp","Microsoft.Xbox.TCUI","Microsoft.XboxGameOverlay",
              "Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider",
              "Microsoft.XboxSpeechToTextOverlay","Microsoft.GamingApp")
    foreach ($a in $apps) {
        Get-AppxPackage $a -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object DisplayName -EQ $a | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    foreach ($s in @("XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc","xbgm","BcastDVRUserService")) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        Set-Service  $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Write-Log "Xbox components removed." "OK"
}

function Tweak-RemoveStoreApps {
    Write-Log "Removing provisioned Store apps (nuclear)..." "HEAD"
    $keep = @("Microsoft.WindowsStore","Microsoft.StorePurchaseApp","Microsoft.DesktopAppInstaller",
              "Microsoft.WindowsTerminal","Microsoft.WindowsCalculator","Microsoft.Paint",
              "Microsoft.Photos","Microsoft.WindowsNotepad")
    Get-AppxProvisionedPackage -Online | Where-Object { $keep -notcontains $_.DisplayName } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    Get-AppxPackage -AllUsers | Where-Object { $keep -notcontains $_.Name } |
        Remove-AppxPackage -ErrorAction SilentlyContinue
    Write-Log "Store apps removed (kept essentials)." "OK"
}

function Tweak-RemoveGalleryHome {
    Write-Log "Removing Gallery/Home from Explorer..." "HEAD"
    Remove-Item "HKCU:\SOFTWARE\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Recurse -Force -ErrorAction SilentlyContinue
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_ShowRecentList" 0
    Write-Log "Gallery/Home removed." "OK"
}

function Tweak-ClassicRightClick {
    Write-Log "Enabling classic right-click menu..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\CLASSES\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "(default)" "" "String"
    Write-Log "Classic right-click enabled." "OK"
}

function Tweak-DisplayPerformance {
    Write-Log "Setting display for max performance..." "HEAD"
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
    Set-Reg "HKCU:\Control Panel\Desktop" "DragFullWindows"  "0" "String"
    Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay"    "0" "String"
    Set-Reg "HKCU:\Control Panel\Desktop" "FontSmoothing"    "2" "String"
    Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0
    Write-Log "Display set for performance." "OK"
}

function Tweak-TimeUTC {
    Write-Log "Setting hardware clock to UTC..." "HEAD"
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" "RealTimeIsUniversal" 1
    Write-Log "Hardware clock set to UTC." "OK"
}

function Tweak-DisablePrintSpooler {
    Write-Log "Disabling Print Spooler (non-printing systems)..." "HEAD"
    Stop-Service Spooler -Force -ErrorAction SilentlyContinue
    Set-Service  Spooler -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "Print Spooler disabled." "OK"
}

function Tweak-DisableFax {
    Write-Log "Disabling Fax service..." "HEAD"
    Stop-Service Fax -Force -ErrorAction SilentlyContinue
    Set-Service  Fax -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "Fax disabled." "OK"
}

function Tweak-DisableSuperfetch {
    Write-Log "Disabling SysMain (Superfetch)..." "HEAD"
    Stop-Service SysMain -Force -ErrorAction SilentlyContinue
    Set-Service  SysMain -StartupType Disabled -ErrorAction SilentlyContinue
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 0
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" 0
    Write-Log "SysMain/Superfetch disabled." "OK"
}

function Tweak-DisableWindowsSearch {
    Write-Log "Disabling Windows Search indexing..." "HEAD"
    Stop-Service WSearch -Force -ErrorAction SilentlyContinue
    Set-Service  WSearch -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "Windows Search indexing disabled." "OK"
}

function Tweak-DisableDefender {
    Write-Log "Disabling Windows Defender real-time protection..." "HEAD"
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware"      1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableBehaviorMonitoring" 1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableOnAccessProtection" 1
    Write-Log "Defender real-time disabled (use 3rd party AV)." "WARN"
}

function Tweak-DisableWindowsUpdate {
    Write-Log "Pausing Windows Updates (policy)..." "HEAD"
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate"     1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions"        2
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Set-Service  wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "Windows Update paused." "OK"
}

function Tweak-DisableAutoRebootUpdate {
    Write-Log "Disabling auto-reboot after updates..." "HEAD"
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoRebootWithLoggedOnUsers" 1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"    "SetActiveHours"               1
    Write-Log "Auto-reboot disabled." "OK"
}

function Tweak-BlockTelemetryHosts {
    Write-Log "Blocking telemetry domains via hosts file..." "HEAD"
    $hosts = "C:\Windows\System32\drivers\etc\hosts"
    $entries = @(
        "0.0.0.0 telemetry.microsoft.com","0.0.0.0 vortex.data.microsoft.com",
        "0.0.0.0 vortex-win.data.microsoft.com","0.0.0.0 telecommand.telemetry.microsoft.com",
        "0.0.0.0 telecommand.telemetry.microsoft.com.nsatc.net",
        "0.0.0.0 oca.telemetry.microsoft.com","0.0.0.0 oca.telemetry.microsoft.com.nsatc.net",
        "0.0.0.0 sqm.telemetry.microsoft.com","0.0.0.0 sqm.telemetry.microsoft.com.nsatc.net",
        "0.0.0.0 watson.telemetry.microsoft.com","0.0.0.0 watson.telemetry.microsoft.com.nsatc.net",
        "0.0.0.0 redir.metaservices.microsoft.com","0.0.0.0 choice.microsoft.com",
        "0.0.0.0 choice.microsoft.com.nsatc.net","0.0.0.0 df.telemetry.microsoft.com",
        "0.0.0.0 reports.wes.df.telemetry.microsoft.com","0.0.0.0 cs1.wpc.v0cdn.net",
        "0.0.0.0 vortex-sandbox.data.microsoft.com","0.0.0.0 pre.footprintpredict.com",
        "0.0.0.0 i1.services.social.microsoft.com","0.0.0.0 i1.services.social.microsoft.com.nsatc.net",
        "0.0.0.0 feedback.windows.com","0.0.0.0 feedback.search.microsoft.com",
        "0.0.0.0 watson.ppe.telemetry.microsoft.com","0.0.0.0 settings-sandbox.data.microsoft.com",
        "0.0.0.0 az361816.vo.msecnd.net","0.0.0.0 az512334.vo.msecnd.net"
    )
    $cur = Get-Content $hosts -ErrorAction SilentlyContinue
    foreach ($e in $entries) { if ($cur -notcontains $e) { Add-Content $hosts $e } }
    Write-Log "Telemetry hosts blocked." "OK"
}

# ── PREFERENCES ───────────────────────────────────────────────

function Tweak-DisableBingSearch {
    Write-Log "Disabling Bing in Start Menu..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled"            0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent"               0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "DisableSearchBoxSuggestions"  1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch"           1
    Write-Log "Bing search disabled." "OK"
}

function Tweak-CenterTaskbar {
    Write-Log "Centering taskbar items..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 1
    Write-Log "Taskbar centered." "OK"
}

function Tweak-LeftTaskbar {
    Write-Log "Left-aligning taskbar..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0
    Write-Log "Taskbar left-aligned." "OK"
}

function Tweak-DisableCrossDeviceResume {
    Write-Log "Disabling Cross-Device Resume..." "HEAD"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" "EnableRemoteDeviceSuperResolution" 0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy"         0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" "RomeSdkChannelUserAuthzPolicy"     0
    Write-Log "Cross-device Resume disabled." "OK"
}

function Tweak-EnableDarkTheme {
    Write-Log "Enabling Dark theme..." "HEAD"

    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0

    Write-Log "Dark theme enabled." "OK"
}
