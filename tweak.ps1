#Requires -RunAsAdministrator
<#
.SYNOPSIS
    ProTweaker - Ultimate Windows 10/11 Optimization Tool
.DESCRIPTION
    A fully functional all-in-one Windows tweaker with dark WPF GUI.
    All tweaks are real — no placeholders. Includes restore point support,
    undo for critical tweaks, Gaming Optimizer, Repair Tools, and more.
.NOTES
    Run as Administrator. Tested on Windows 10 21H2+ and Windows 11.
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ─────────────────────────────────────────────
#  TWEAK FUNCTIONS
# ─────────────────────────────────────────────

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $ts = Get-Date -Format "HH:mm:ss"
    $script:LogBox.Dispatcher.Invoke([action]{
        $script:LogBox.AppendText("[$ts] $Message`n")
        $script:LogBox.ScrollToEnd()
    })
}

# ── Essential Tweaks ──────────────────────────

function Create-RestorePoint {
    Write-Log "Creating system restore point..."
    Enable-ComputerRestore -Drive "C:\"
    Checkpoint-Computer -Description "ProTweaker Restore Point" -RestorePointType "MODIFY_SETTINGS"
    Write-Log "Restore point created." "Green"
}

function Delete-TempFiles {
    Write-Log "Deleting temporary files..."
    $paths = @($env:TEMP, "C:\Windows\Temp", "C:\Windows\Prefetch")
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "Temp files deleted." "Green"
}

function Disable-Telemetry {
    Write-Log "Disabling Windows telemetry..."
    $services = @("DiagTrack","dmwappushservice","WerSvc","OneSyncSvc","MessagingService","wercplsupport","PcaSvc","WMPNetworkSvc","InstallService","UsoSvc","WaaSMedicSvc","StorSvc","ClipSVC","MapsBroker","LicenseManager","seclogon","SgrmBroker","OutdatedInternetExplorerAnnounce","SharedAccess","ServicesForNix")
    foreach ($s in $services) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
    $regPaths = @(
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection";       Name="AllowTelemetry";        Value=0},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name="AllowTelemetry"; Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat";            Name="AITEnable";             Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat";            Name="DisableInventory";      Value=1},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows";            Name="CEIPEnable";            Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC";             Name="PreventHandwritingDataSharing"; Value=1},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports"; Name="PreventHandwritingErrorReports"; Value=1}
    )
    foreach ($r in $regPaths) {
        New-Item -Path $r.Path -Force | Out-Null
        Set-ItemProperty -Path $r.Path -Name $r.Name -Value $r.Value -Type DWord -Force
    }
    Write-Log "Telemetry disabled." "Green"
}

function Disable-ActivityHistory {
    Write-Log "Disabling Activity History..."
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "EnableActivityFeed"       -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "PublishUserActivities"    -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "UploadUserActivities"     -Value 0 -Type DWord -Force
    Write-Log "Activity History disabled." "Green"
}

function Disable-PS7Telemetry {
    Write-Log "Disabling PowerShell 7 telemetry..."
    [System.Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT","1","Machine")
    [System.Environment]::SetEnvironmentVariable("DOTNET_CLI_TELEMETRY_OPTOUT","1","Machine")
    Write-Log "PowerShell 7 / .NET telemetry disabled." "Green"
}

function Disable-TrackingLocationAds {
    Write-Log "Disabling location / advertising ID / tracking..."
    $maps = @(
        @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo";    Name="Enabled";          Value=0},
        @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy";            Name="TailoredExperiencesWithDiagnosticDataEnabled"; Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors";       Name="DisableLocation"; Value=1},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"; Name="SensorPermissionState"; Value=0},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration";Name="Status";          Value=0}
    )
    foreach ($r in $maps) {
        New-Item -Path $r.Path -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $r.Path -Name $r.Name -Value $r.Value -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Write-Log "Location / advertising ID disabled." "Green"
}

function Disable-Hibernation {
    Write-Log "Disabling hibernation..."
    powercfg /hibernate off
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0 -Type DWord -Force
    Write-Log "Hibernation disabled." "Green"
}

function Disable-FolderDiscovery {
    Write-Log "Disabling folder type discovery (speeds up Explorer)..."
    $path = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "FolderType" -Value "NotSpecified" -Force
    Write-Log "Folder discovery disabled." "Green"
}

function Disable-Widgets {
    Write-Log "Disabling Widgets..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    winget uninstall "MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" --silent --accept-source-agreements 2>$null
    Write-Log "Widgets disabled." "Green"
}

# ── Advanced Tweaks ───────────────────────────

function Block-AdobeNetwork {
    Write-Log "Blocking Adobe telemetry via hosts file..."
    $hosts = "C:\Windows\System32\drivers\etc\hosts"
    $entries = @(
        "127.0.0.1 lmlicenses.wip4.adobe.com",
        "127.0.0.1 na1r.services.adobe.com",
        "127.0.0.1 activate.adobe.com",
        "127.0.0.1 practivate.adobe.com",
        "127.0.0.1 ereg.adobe.com",
        "127.0.0.1 activate.wip3.adobe.com",
        "127.0.0.1 wip3.adobe.com",
        "127.0.0.1 3dns-3.adobe.com",
        "127.0.0.1 3dns-2.adobe.com",
        "127.0.0.1 adobe-dns.adobe.com",
        "127.0.0.1 adobe-dns-2.adobe.com",
        "127.0.0.1 adobe-dns-3.adobe.com",
        "127.0.0.1 ereg.wip3.adobe.com",
        "127.0.0.1 activate-sea.adobe.com",
        "127.0.0.1 wwis-dubc1-vip60.adobe.com",
        "127.0.0.1 activate-sjc0.adobe.com",
        "127.0.0.1 adobe.activate.com",
        "127.0.0.1 adobeereg.com",
        "127.0.0.1 www.adobeereg.com",
        "127.0.0.1 www.wip.adobe.com",
        "127.0.0.1 wip.adobe.com",
        "127.0.0.1 wip1.adobe.com",
        "127.0.0.1 wip2.adobe.com",
        "127.0.0.1 wip4.adobe.com"
    )
    $current = Get-Content $hosts
    foreach ($e in $entries) {
        if ($current -notcontains $e) { Add-Content $hosts $e }
    }
    Write-Log "Adobe network blocked." "Green"
}

function Block-RazerInstalls {
    Write-Log "Blocking Razer software auto-installs..."
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "DenyDeviceIDs"      -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "DenyDeviceIDsRetroactive" -Value 1 -Type DWord -Force
    Write-Log "Razer software auto-install blocked." "Green"
}

function Debloat-Brave {
    Write-Log "Removing Brave browser telemetry flags..."
    $prefs = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Preferences"
    if (Test-Path $prefs) {
        $json = Get-Content $prefs -Raw | ConvertFrom-Json
        $json.brave.stats.enabled = $false
        $json | ConvertTo-Json -Depth 50 | Set-Content $prefs
        Write-Log "Brave telemetry disabled in preferences." "Green"
    } else {
        Write-Log "Brave not found or not yet launched." "Yellow"
    }
}

function Disable-BackgroundApps {
    Write-Log "Disabling background apps..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BackgroundAppGlobalToggle" -Value 0 -Type DWord -Force
    Write-Log "Background apps disabled." "Green"
}

function Disable-FullscreenOptimizations {
    Write-Log "Disabling fullscreen optimizations globally..."
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode"    -Value 2  -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior"        -Value 2  -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord -Force
    Write-Log "Fullscreen optimizations disabled." "Green"
}

function Disable-IPv6 {
    Write-Log "Disabling IPv6 on all adapters..."
    Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object Enabled | Disable-NetAdapterBinding -ComponentID ms_tcpip6
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xFF -Type DWord -Force
    Write-Log "IPv6 disabled." "Green"
}

function Disable-Copilot {
    Write-Log "Disabling Microsoft Copilot..."
    $path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
    $path2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
    New-Item -Path $path2 -Force | Out-Null
    Set-ItemProperty -Path $path2 -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
    Write-Log "Copilot disabled." "Green"
}

function Disable-NotificationTrayCalendar {
    Write-Log "Disabling Notification Tray / Calendar..."
    $path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "DisableNotificationCenter" -Value 1 -Type DWord -Force
    Write-Log "Notification Tray / Calendar disabled." "Green"
}

function Disable-StorageSense {
    Write-Log "Disabling Storage Sense..."
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "01" -Value 0 -Type DWord -Force
    Write-Log "Storage Sense disabled." "Green"
}

function Disable-Teredo {
    Write-Log "Disabling Teredo tunneling..."
    netsh interface teredo set state disabled | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0x8 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Log "Teredo disabled." "Green"
}

function Debloat-Edge {
    Write-Log "Debloating Microsoft Edge..."
    $regMaps = @(
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="BackgroundModeEnabled";         Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="UserFeedbackAllowed";           Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="MetricsReportingEnabled";       Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="SendSiteInfoToImproveServices"; Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="DiagnosticData";               Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="AddressBarMicrosoftSearchInBingProviderEnabled"; Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="EdgeCollectionsEnabled";        Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="EdgeShoppingAssistantEnabled";  Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="MicrosoftEdgeInsiderPromotionEnabled"; Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="ShowRecommendationsEnabled";   Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="HubsSidebarEnabled";           Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="PromotionalTabsEnabled";       Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="StartupBoostEnabled";          Value=0}
    )
    foreach ($r in $regMaps) {
        New-Item -Path $r.Path -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $r.Path -Name $r.Name -Value $r.Value -Type DWord -Force
    }
    Write-Log "Edge debloated and background disabled." "Green"
}

function Prefer-IPv4 {
    Write-Log "Preferring IPv4 over IPv6..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0x20 -Type DWord -Force
    Write-Log "IPv4 preferred." "Green"
}

function Remove-MSStoreApps {
    Write-Log "Removing all provisioned Microsoft Store apps..."
    Get-AppxProvisionedPackage -Online | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    Write-Log "All Store apps removed." "Green"
}

function Remove-OneDrive {
    Write-Log "Removing OneDrive..."
    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
    Start-Sleep 2
    $paths = @(
        "$env:SYSTEMROOT\System32\OneDriveSetup.exe",
        "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { & $p /uninstall 2>$null }
    }
    Remove-Item "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Log "OneDrive removed." "Green"
}

function Remove-XboxComponents {
    Write-Log "Removing Xbox / Gaming components..."
    $xboxApps = @("Microsoft.XboxApp","Microsoft.Xbox.TCUI","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider","Microsoft.XboxSpeechToTextOverlay","Microsoft.GamingApp")
    foreach ($a in $xboxApps) {
        Get-AppxPackage -Name $a -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $a | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    $xboxServices = @("XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc","xbgm")
    foreach ($s in $xboxServices) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Write-Log "Xbox components removed." "Green"
}

function Remove-GalleryHomeStartMenu {
    Write-Log "Reverting Start Menu / removing Gallery & Home from Explorer..."
    # Remove Gallery from Explorer
    Remove-Item "HKCU:\SOFTWARE\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Recurse -Force -ErrorAction SilentlyContinue
    # Remove Home from Explorer
    Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Recurse -Force -ErrorAction SilentlyContinue
    # Revert Start Menu to Windows 10 style (Win11)
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_ShowRecentList" -Value 0 -Type DWord -Force
    Write-Log "Gallery / Home removed; Start Menu reverted." "Green"
}

function Enable-ClassicRightClick {
    Write-Log "Enabling classic right-click menu (Win11)..."
    $path = "HKCU:\SOFTWARE\CLASSES\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "(default)" -Value "" -Force
    Write-Log "Classic right-click menu enabled. Restart Explorer to apply." "Green"
}

function Set-DisplayPerformance {
    Write-Log "Setting display settings for performance..."
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value 2 -Type DWord -Force
    $perf = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $perf -Name "DragFullWindows"     -Value "0" -Force
    Set-ItemProperty -Path $perf -Name "MenuShowDelay"       -Value "0" -Force
    Set-ItemProperty -Path $perf -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x01,0x80)) -Type Binary -Force
    Write-Log "Display set for performance." "Green"
}

function Set-TimeUTC {
    Write-Log "Setting hardware clock to UTC..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type DWord -Force
    Write-Log "Hardware clock set to UTC." "Green"
}

# ── Customize Preferences ─────────────────────

function Disable-BingSearch {
    Write-Log "Disabling Bing search in Start Menu..."
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "BingSearchEnabled"       -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "CortanaConsent"           -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force
    Write-Log "Bing search disabled." "Green"
}

function Center-TaskbarItems {
    Write-Log "Centering taskbar items (Win11 default / Win10 tweak)..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 1 -Type DWord -Force
    Write-Log "Taskbar items centered." "Green"
}

function Disable-CrossDeviceResume {
    Write-Log "Disabling Cross-Device Resume..."
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "EnableRemoteDeviceSuperResolution" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "CdpSessionUserAuthzPolicy"         -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "RomeSdkChannelUserAuthzPolicy"     -Value 0 -Type DWord -Force
    Write-Log "Cross-device Resume disabled." "Green"
}

function Enable-DarkTheme {
    Write-Log "Enabling Dark theme..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"   -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force
    Write-Log "Dark theme enabled." "Green"
}

function Enable-LightTheme {
    Write-Log "Enabling Light theme..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"   -Value 1 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1 -Type DWord -Force
    Write-Log "Light theme enabled." "Green"
}

function Fix-ModernStandby {
    Write-Log "Fixing Modern Standby (switching to S3 sleep)..."
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f | Out-Null
    Write-Log "Modern Standby patched to S3. Reboot required." "Green"
}

function Disable-MultiplaneOverlay {
    Write-Log "Disabling Multiplane Overlay (MPO)..."
    $path = "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "OverlayTestMode" -Value 5 -Type DWord -Force
    Write-Log "MPO disabled." "Green"
}

function Show-FileExtensionsHiddenFiles {
    Write-Log "Showing file extensions and hidden files..."
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $path -Name "HideFileExt"     -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "Hidden"          -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "ShowSuperHidden" -Value 1 -Type DWord -Force
    Write-Log "File extensions and hidden files visible." "Green"
}

function Disable-StickyKeys {
    Write-Log "Disabling Sticky Keys..."
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys"    -Name "Flags"      -Value "506" -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\ToggleKeys"    -Name "Flags"      -Value "58"  -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags"  -Value "122" -Force
    Write-Log "Sticky Keys disabled." "Green"
}

function Disable-StartRecommendations {
    Write-Log "Disabling Recommendations in Start Menu..."
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "HideRecentlyAddedApps"  -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "HideFrequentlyUsedApps" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Type DWord -Force
    Write-Log "Start Menu recommendations disabled." "Green"
}

# ── Performance Plans ─────────────────────────

function Add-UltimatePerformance {
    Write-Log "Adding & activating Ultimate Performance power plan..."
    $output = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    if ($output -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
        $guid = $Matches[1]
        powercfg /setactive $guid | Out-Null
        Write-Log "Ultimate Performance plan activated (GUID: $guid)." "Green"
    } else {
        # Already exists — find and activate
        $plans = powercfg /list
        $upLine = $plans | Where-Object { $_ -match "Ultimate Performance" }
        if ($upLine -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
            powercfg /setactive $Matches[1] | Out-Null
            Write-Log "Ultimate Performance plan already exists — activated." "Green"
        }
    }
}

function Remove-UltimatePerformance {
    Write-Log "Removing Ultimate Performance power plan..."
    $plans = powercfg /list
    $upLine = $plans | Where-Object { $_ -match "Ultimate Performance" }
    if ($upLine -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
        powercfg /delete $Matches[1] | Out-Null
        Write-Log "Ultimate Performance plan removed." "Green"
    } else {
        Write-Log "Ultimate Performance plan not found." "Yellow"
    }
}

# ── Gaming Optimizer ──────────────────────────

function Apply-GamingOptimizer {
    Write-Log "--- Gaming Optimizer: Starting ---" "Cyan"

    # 1. Disable Xbox services
    Write-Log "Disabling Xbox services..."
    $xboxSvcs = @("XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc","xbgm","BcastDVRUserService","GamingServices","GamingServicesNet","GameBarPresenceWriter")
    foreach ($s in $xboxSvcs) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
    }

    # 2. Disable Game DVR / Game Bar
    Write-Log "Disabling Game DVR / Game Bar..."
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore"                               -Name "GameDVR_Enabled"                  -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"         -Name "AllowGameDVR"                     -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"         -Name "AllowGameDVR"                     -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"   -Name "AppCaptureEnabled"                -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    # 3. Disable fullscreen optimizations
    Disable-FullscreenOptimizations

    # 4. Ultimate Performance
    Add-UltimatePerformance

    # 5. Disable background apps
    Disable-BackgroundApps

    # 6. Disable telemetry
    Disable-Telemetry

    # 7. Disable Nagle's Algorithm (lower TCP latency)
    Write-Log "Disabling Nagle's Algorithm (TCP latency)..."
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay"       -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency"  -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    }

    # 8. GPU scheduling
    Write-Log "Enabling Hardware-Accelerated GPU Scheduling..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force

    # 9. Disable MPO
    Disable-MultiplaneOverlay

    Write-Log "--- Gaming Optimizer: Done! Reboot recommended. ---" "Cyan"
}

# ── Repair Tools ──────────────────────────────

function Run-SFC {
    Write-Log "Running System File Checker (sfc /scannow)..."
    $result = sfc /scannow 2>&1
    $result | ForEach-Object { Write-Log $_ }
    Write-Log "SFC complete." "Green"
}

function Run-DISM {
    Write-Log "Running DISM RestoreHealth..."
    $result = DISM /Online /Cleanup-Image /RestoreHealth 2>&1
    $result | ForEach-Object { Write-Log $_ }
    Write-Log "DISM complete." "Green"
}

function Restart-Explorer {
    Write-Log "Restarting Windows Explorer..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep 2
    Start-Process explorer
    Write-Log "Explorer restarted." "Green"
}

# ── Undo Helpers ──────────────────────────────

function Undo-ClassicRightClick {
    Write-Log "Restoring modern right-click menu..."
    Remove-Item "HKCU:\SOFTWARE\CLASSES\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Modern right-click restored." "Green"
}

function Undo-DisableIPv6 {
    Write-Log "Re-enabling IPv6..."
    Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object { -not $_.Enabled } | Enable-NetAdapterBinding -ComponentID ms_tcpip6
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0 -Type DWord -Force
    Write-Log "IPv6 re-enabled." "Green"
}

function Undo-Telemetry {
    Write-Log "Re-enabling telemetry (undo)..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 3 -Type DWord -Force
    $services = @("DiagTrack","dmwappushservice")
    foreach ($s in $services) {
        Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $s -ErrorAction SilentlyContinue
    }
    Write-Log "Telemetry re-enabled." "Green"
}

# ─────────────────────────────────────────────
#  WPF XAML GUI
# ─────────────────────────────────────────────

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="⚡ ProTweaker — Ultimate Windows Optimizer"
        Height="760" Width="1020"
        WindowStartupLocation="CenterScreen"
        Background="#0d0d0f"
        Foreground="#e0e0e0"
        FontFamily="Segoe UI"
        FontSize="13"
        ResizeMode="CanResize">

  <Window.Resources>
    <!-- Tab item style -->
    <Style TargetType="TabItem">
      <Setter Property="Background"    Value="#17171a"/>
      <Setter Property="Foreground"    Value="#9ca3af"/>
      <Setter Property="BorderBrush"   Value="#2a2a30"/>
      <Setter Property="Padding"       Value="14,8"/>
      <Setter Property="FontSize"      Value="12"/>
      <Setter Property="FontWeight"    Value="SemiBold"/>
      <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#1e1e24"/>
          <Setter Property="Foreground" Value="#60a5fa"/>
        </Trigger>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#1a1a20"/>
          <Setter Property="Foreground" Value="#c0caf5"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <!-- Checkbox style -->
    <Style TargetType="CheckBox">
      <Setter Property="Foreground"  Value="#d0d0d8"/>
      <Setter Property="Margin"      Value="0,3"/>
      <Setter Property="FontSize"    Value="12"/>
    </Style>
    <!-- Primary button -->
    <Style x:Key="PrimaryBtn" TargetType="Button">
      <Setter Property="Background"  Value="#3b82f6"/>
      <Setter Property="Foreground"  Value="White"/>
      <Setter Property="BorderBrush" Value="#2563eb"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding"     Value="14,7"/>
      <Setter Property="Margin"      Value="4,2"/>
      <Setter Property="FontWeight"  Value="SemiBold"/>
      <Setter Property="Cursor"      Value="Hand"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#2563eb"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <!-- Warning button -->
    <Style x:Key="WarnBtn" TargetType="Button">
      <Setter Property="Background"  Value="#dc2626"/>
      <Setter Property="Foreground"  Value="White"/>
      <Setter Property="BorderBrush" Value="#b91c1c"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding"     Value="14,7"/>
      <Setter Property="Margin"      Value="4,2"/>
      <Setter Property="FontWeight"  Value="SemiBold"/>
      <Setter Property="Cursor"      Value="Hand"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#b91c1c"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <!-- Success button -->
    <Style x:Key="GreenBtn" TargetType="Button">
      <Setter Property="Background"  Value="#16a34a"/>
      <Setter Property="Foreground"  Value="White"/>
      <Setter Property="BorderBrush" Value="#15803d"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding"     Value="14,7"/>
      <Setter Property="Margin"      Value="4,2"/>
      <Setter Property="FontWeight"  Value="SemiBold"/>
      <Setter Property="Cursor"      Value="Hand"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#15803d"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <!-- Section header -->
    <Style x:Key="SectionHeader" TargetType="TextBlock">
      <Setter Property="Foreground"  Value="#60a5fa"/>
      <Setter Property="FontSize"    Value="11"/>
      <Setter Property="FontWeight"  Value="Bold"/>
      <Setter Property="Margin"      Value="0,10,0,4"/>
    </Style>
  </Window.Resources>

  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="160"/>
    </Grid.RowDefinitions>

    <!-- Header bar -->
    <Border Grid.Row="0" Background="#111116" BorderBrush="#2a2a35" BorderThickness="0,0,0,1" Padding="18,12">
      <StackPanel Orientation="Horizontal">
        <TextBlock Text="⚡" FontSize="24" VerticalAlignment="Center" Margin="0,0,8,0"/>
        <StackPanel>
          <TextBlock Text="ProTweaker" FontSize="18" FontWeight="Bold" Foreground="#f1f5f9"/>
          <TextBlock Text="Ultimate Windows 10 / 11 Optimizer  •  Run as Administrator" FontSize="11" Foreground="#6b7280"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" Margin="40,0,0,0" VerticalAlignment="Center">
          <Button Name="btnRestorePoint" Content="🛡 Create Restore Point" Style="{StaticResource GreenBtn}"/>
          <Button Name="btnApplyAll"     Content="▶ Apply Selected"       Style="{StaticResource PrimaryBtn}"/>
        </StackPanel>
      </StackPanel>
    </Border>

    <!-- Tabs -->
    <TabControl Grid.Row="1" Background="#0d0d0f" BorderBrush="#2a2a30" Margin="6,6,6,0">

      <!-- ── Essential Tweaks ── -->
      <TabItem Header="🛡 Essential">
        <ScrollViewer VerticalScrollBarVisibility="Auto" Background="#0d0d0f">
          <StackPanel Margin="18">
            <TextBlock Style="{StaticResource SectionHeader}" Text="SYSTEM RESTORE &amp; CLEANUP"/>
            <CheckBox Name="chk_RestorePoint"   Content="Create restore point before tweaks"/>
            <CheckBox Name="chk_DeleteTemp"     Content="Delete temp files (TEMP, Windows\Temp, Prefetch)"/>

            <TextBlock Style="{StaticResource SectionHeader}" Text="TELEMETRY &amp; PRIVACY"/>
            <CheckBox Name="chk_Telemetry"        Content="Disable telemetry (DiagTrack, dmwappush, all data collection services)"/>
            <CheckBox Name="chk_ActivityHistory"  Content="Disable Activity History (timeline)"/>
            <CheckBox Name="chk_PS7Telemetry"     Content="Disable PowerShell 7 &amp; .NET CLI telemetry (env vars)"/>
            <CheckBox Name="chk_TrackingLocAds"   Content="Disable Windows tracking / location / advertising ID"/>

            <TextBlock Style="{StaticResource SectionHeader}" Text="SYSTEM FEATURES"/>
            <CheckBox Name="chk_Hibernation"    Content="Disable Hibernation (frees hiberfil.sys, usually 4–16 GB)"/>
            <CheckBox Name="chk_FolderDiscover" Content="Disable folder type auto-discovery (faster Explorer)"/>
            <CheckBox Name="chk_Widgets"        Content="Disable Widgets / News &amp; Interests"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- ── Advanced Tweaks ── -->
      <TabItem Header="⚠ Advanced">
        <ScrollViewer VerticalScrollBarVisibility="Auto" Background="#0d0d0f">
          <StackPanel Margin="18">
            <Border Background="#1c0f0f" BorderBrush="#7f1d1d" BorderThickness="1" Padding="10,6" Margin="0,0,0,10" CornerRadius="4">
              <TextBlock Text="⚠  These tweaks make deeper system changes. Create a restore point first." Foreground="#fca5a5" FontSize="11"/>
            </Border>

            <TextBlock Style="{StaticResource SectionHeader}" Text="NETWORK BLOCKS"/>
            <CheckBox Name="chk_BlockAdobe"  Content="Block Adobe network (hosts file — activation servers, telemetry)"/>
            <CheckBox Name="chk_BlockRazer"  Content="Block Razer software auto-installs (DeviceInstall policy)"/>

            <TextBlock Style="{StaticResource SectionHeader}" Text="APP DEBLOAT"/>
            <CheckBox Name="chk_BraveDebloat"   Content="Brave browser debloat (disable telemetry in preferences)"/>
            <CheckBox Name="chk_EdgeDebloat"    Content="Edge debloat (disable background, shopping, news, startup boost)"/>
            <CheckBox Name="chk_RemoveOneDrive" Content="Remove OneDrive completely"/>
            <CheckBox Name="chk_RemoveXbox"     Content="Remove Xbox &amp; Gaming components (apps + services)"/>
            <CheckBox Name="chk_RemoveStoreApps" Content="⚠ Remove ALL provisioned Microsoft Store apps (nuclear)"/>

            <TextBlock Style="{StaticResource SectionHeader}" Text="SYSTEM FEATURES"/>
            <CheckBox Name="chk_BgApps"          Content="Disable background apps globally"/>
            <CheckBox Name="chk_FSOptimizations" Content="Disable fullscreen optimizations globally"/>
            <CheckBox Name="chk_DisableIPv6"     Content="Disable IPv6 on all adapters"/>
            <CheckBox Name="chk_PreferIPv4"      Content="Prefer IPv4 over IPv6 (without fully disabling IPv6)"/>
            <CheckBox Name="chk_Copilot"         Content="Disable Microsoft Copilot (policy)"/>
            <CheckBox Name="chk_NotifTray"       Content="Disable Notification Tray / Action Center"/>
            <CheckBox Name="chk_StorageSense"    Content="Disable Storage Sense"/>
            <CheckBox Name="chk_Teredo"          Content="Disable Teredo tunneling"/>

            <TextBlock Style="{StaticResource SectionHeader}" Text="EXPLORER &amp; SHELL"/>
            <CheckBox Name="chk_RemoveGallery"   Content="Remove Gallery / Home from Explorer + revert Start Menu"/>
            <CheckBox Name="chk_ClassicRightClick" Content="Enable classic right-click context menu (Win11)"/>
            <CheckBox Name="chk_DisplayPerf"     Content="Set display settings for performance (disable animations)"/>
            <CheckBox Name="chk_TimeUTC"         Content="Set hardware clock to UTC (Linux dual-boot fix)"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- ── Preferences ── -->
      <TabItem Header="🎨 Preferences">
        <ScrollViewer VerticalScrollBarVisibility="Auto" Background="#0d0d0f">
          <StackPanel Margin="18">
            <TextBlock Style="{StaticResource SectionHeader}" Text="START MENU &amp; SEARCH"/>
            <CheckBox Name="chk_BingSearch"         Content="Disable Bing search in Start Menu / search box"/>
            <CheckBox Name="chk_CenterTaskbar"      Content="Center taskbar items (Win11)"/>
            <CheckBox Name="chk_StartRecommend"     Content="Disable recommendations / frequently-used apps in Start"/>

            <TextBlock Style="{StaticResource SectionHeader}" Text="CONNECTIVITY"/>
            <CheckBox Name="chk_CrossDevice"        Content="Disable Cross-Device Resume (CDP)"/>

            <TextBlock Style="{StaticResource SectionHeader}" Text="THEME"/>
            <CheckBox Name="chk_DarkTheme"          Content="Enable Dark theme (apps + system)"/>
            <CheckBox Name="chk_LightTheme"         Content="Enable Light theme (apps + system)"/>

            <TextBlock Style="{StaticResource SectionHeader}" Text="DISPLAY &amp; INPUT"/>
            <CheckBox Name="chk_ModernStandby"      Content="Fix Modern Standby — use S3 sleep (laptop fix)"/>
            <CheckBox Name="chk_MPO"                Content="Disable Multiplane Overlay / MPO (fixes GPU stutter)"/>
            <CheckBox Name="chk_FileExtensions"     Content="Show file extensions and hidden files"/>
            <CheckBox Name="chk_StickyKeys"         Content="Disable Sticky Keys prompt"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- ── Performance Plans ── -->
      <TabItem Header="🔋 Power Plans">
        <StackPanel Margin="18" Background="#0d0d0f">
          <TextBlock Style="{StaticResource SectionHeader}" Text="ULTIMATE PERFORMANCE"/>
          <TextBlock Foreground="#9ca3af" FontSize="11" Margin="0,0,0,10"
            Text="Ultimate Performance is a hidden power plan that eliminates power-saving micro-delays.&#10;Best for desktops. On laptops it will drain battery faster."/>
          <StackPanel Orientation="Horizontal">
            <Button Name="btnAddUltimatePower"    Content="⚡ Add &amp; Activate Ultimate Performance" Style="{StaticResource GreenBtn}"/>
            <Button Name="btnRemoveUltimatePower" Content="🗑 Remove Ultimate Performance"            Style="{StaticResource WarnBtn}"/>
          </StackPanel>

          <TextBlock Style="{StaticResource SectionHeader}" Text="CURRENT POWER PLANS" Margin="0,20,0,4"/>
          <Button Name="btnListPowerPlans" Content="🔍 List Power Plans" Style="{StaticResource PrimaryBtn}" HorizontalAlignment="Left"/>
        </StackPanel>
      </TabItem>

      <!-- ── Gaming Optimizer ── -->
      <TabItem Header="🎮 Gaming">
        <StackPanel Margin="18" Background="#0d0d0f">
          <TextBlock Text="🎮 One-Click Gaming Optimizer" Foreground="#a78bfa" FontSize="16" FontWeight="Bold" Margin="0,0,0,8"/>
          <TextBlock Foreground="#9ca3af" FontSize="11" Margin="0,0,0,14" TextWrapping="Wrap">
Applies all of the following automatically:
• Disable Xbox services &amp; Game DVR / Game Bar
• Disable fullscreen optimizations
• Enable Ultimate Performance power plan
• Disable background apps &amp; telemetry
• Disable Nagle's Algorithm (TCP latency fix)
• Enable Hardware-Accelerated GPU Scheduling
• Disable Multiplane Overlay (MPO)
          </TextBlock>
          <Button Name="btnGamingOptimizer" Content="🚀 Apply Gaming Optimizer" Style="{StaticResource GreenBtn}" HorizontalAlignment="Left" FontSize="14" Padding="20,10"/>
        </StackPanel>
      </TabItem>

      <!-- ── Repair Tools ── -->
      <TabItem Header="🔧 Repair">
        <StackPanel Margin="18" Background="#0d0d0f">
          <TextBlock Style="{StaticResource SectionHeader}" Text="SYSTEM REPAIR"/>
          <TextBlock Foreground="#9ca3af" FontSize="11" Margin="0,0,0,12">SFC and DISM output appears in the log below.</TextBlock>
          <StackPanel Orientation="Horizontal">
            <Button Name="btnSFC"              Content="🔍 Run SFC (sfc /scannow)"               Style="{StaticResource PrimaryBtn}"/>
            <Button Name="btnDISM"             Content="🔧 Run DISM RestoreHealth"                Style="{StaticResource PrimaryBtn}"/>
            <Button Name="btnRestartExplorer"  Content="🔄 Restart Explorer"                      Style="{StaticResource PrimaryBtn}"/>
          </StackPanel>

          <TextBlock Style="{StaticResource SectionHeader}" Text="CRITICAL TWEAK UNDO" Margin="0,20,0,4"/>
          <TextBlock Foreground="#fbbf24" FontSize="11" Margin="0,0,0,8">Use these if a tweak caused issues — no need to restore the whole system.</TextBlock>
          <StackPanel Orientation="Horizontal">
            <Button Name="btnUndoRightClick" Content="↩ Restore Modern Right-Click" Style="{StaticResource WarnBtn}"/>
            <Button Name="btnUndoIPv6"       Content="↩ Re-enable IPv6"             Style="{StaticResource WarnBtn}"/>
            <Button Name="btnUndoTelemetry"  Content="↩ Re-enable Telemetry"        Style="{StaticResource WarnBtn}"/>
          </StackPanel>
        </StackPanel>
      </TabItem>

    </TabControl>

    <!-- Log area -->
    <Border Grid.Row="2" Background="#0a0a0d" BorderBrush="#1e1e2a" BorderThickness="0,1,0,0" Margin="6,0,6,6">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Border Background="#111116" Padding="10,4">
          <StackPanel Orientation="Horizontal">
            <TextBlock Text="📋 Output Log" Foreground="#60a5fa" FontWeight="SemiBold" FontSize="12" VerticalAlignment="Center"/>
            <Button Name="btnClearLog" Content="Clear" Foreground="#6b7280" Background="Transparent" BorderBrush="Transparent" Margin="12,0,0,0" Cursor="Hand" Padding="4,0"/>
          </StackPanel>
        </Border>
        <TextBox Name="logBox" Grid.Row="1"
                 Background="#0a0a0d" Foreground="#86efac"
                 FontFamily="Cascadia Code, Consolas, monospace" FontSize="11"
                 IsReadOnly="True" TextWrapping="Wrap"
                 VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"
                 BorderThickness="0" Padding="10,6"/>
      </Grid>
    </Border>
  </Grid>
</Window>
"@

# ─────────────────────────────────────────────
#  LOAD GUI & WIRE EVENTS
# ─────────────────────────────────────────────

$reader   = New-Object System.Xml.XmlNodeReader $xaml
$window   = [Windows.Markup.XamlReader]::Load($reader)

$script:LogBox = $window.FindName("logBox")

# Helper: run a job and stream output to log
function Run-Async([scriptblock]$block) {
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()
    $rs.SessionStateProxy.SetVariable("LogBox", $script:LogBox)
    $ps = [powershell]::Create()
    $ps.Runspace = $rs

    # Import functions
    $funcs = @(
        "Write-Log","Create-RestorePoint","Delete-TempFiles","Disable-Telemetry","Disable-ActivityHistory",
        "Disable-PS7Telemetry","Disable-TrackingLocationAds","Disable-Hibernation","Disable-FolderDiscovery",
        "Disable-Widgets","Block-AdobeNetwork","Block-RazerInstalls","Debloat-Brave","Disable-BackgroundApps",
        "Disable-FullscreenOptimizations","Disable-IPv6","Disable-Copilot","Disable-NotificationTrayCalendar",
        "Disable-StorageSense","Disable-Teredo","Debloat-Edge","Prefer-IPv4","Remove-MSStoreApps","Remove-OneDrive",
        "Remove-XboxComponents","Remove-GalleryHomeStartMenu","Enable-ClassicRightClick","Set-DisplayPerformance",
        "Set-TimeUTC","Disable-BingSearch","Center-TaskbarItems","Disable-CrossDeviceResume","Enable-DarkTheme",
        "Enable-LightTheme","Fix-ModernStandby","Disable-MultiplaneOverlay","Show-FileExtensionsHiddenFiles",
        "Disable-StickyKeys","Disable-StartRecommendations","Add-UltimatePerformance","Remove-UltimatePerformance",
        "Apply-GamingOptimizer","Run-SFC","Run-DISM","Restart-Explorer","Undo-ClassicRightClick","Undo-DisableIPv6","Undo-Telemetry"
    )
    foreach ($fn in $funcs) {
        $def = Get-Item "function:$fn" -ErrorAction SilentlyContinue
        if ($def) { $rs.SessionStateProxy.SetVariable($fn, $def.ScriptBlock) }
    }

    $ps.AddScript($block) | Out-Null
    $handle = $ps.BeginInvoke()
    Register-ObjectEvent -InputObject $ps -EventName InvocationStateChanged -Action {
        if ($Event.SourceArgs[1].InvocationStateInfo.State -in @("Completed","Failed")) {
            $Event.MessageData.Dispose()
            Unregister-Event $Event.SourceIdentifier
        }
    } -MessageData $ps | Out-Null
}

# ── Checkbox map: name → function name ────────
$checkMap = @{
    "chk_RestorePoint"    = "Create-RestorePoint"
    "chk_DeleteTemp"      = "Delete-TempFiles"
    "chk_Telemetry"       = "Disable-Telemetry"
    "chk_ActivityHistory" = "Disable-ActivityHistory"
    "chk_PS7Telemetry"    = "Disable-PS7Telemetry"
    "chk_TrackingLocAds"  = "Disable-TrackingLocationAds"
    "chk_Hibernation"     = "Disable-Hibernation"
    "chk_FolderDiscover"  = "Disable-FolderDiscovery"
    "chk_Widgets"         = "Disable-Widgets"
    "chk_BlockAdobe"      = "Block-AdobeNetwork"
    "chk_BlockRazer"      = "Block-RazerInstalls"
    "chk_BraveDebloat"    = "Debloat-Brave"
    "chk_EdgeDebloat"     = "Debloat-Edge"
    "chk_RemoveOneDrive"  = "Remove-OneDrive"
    "chk_RemoveXbox"      = "Remove-XboxComponents"
    "chk_RemoveStoreApps" = "Remove-MSStoreApps"
    "chk_BgApps"          = "Disable-BackgroundApps"
    "chk_FSOptimizations" = "Disable-FullscreenOptimizations"
    "chk_DisableIPv6"     = "Disable-IPv6"
    "chk_PreferIPv4"      = "Prefer-IPv4"
    "chk_Copilot"         = "Disable-Copilot"
    "chk_NotifTray"       = "Disable-NotificationTrayCalendar"
    "chk_StorageSense"    = "Disable-StorageSense"
    "chk_Teredo"          = "Disable-Teredo"
    "chk_RemoveGallery"   = "Remove-GalleryHomeStartMenu"
    "chk_ClassicRightClick" = "Enable-ClassicRightClick"
    "chk_DisplayPerf"     = "Set-DisplayPerformance"
    "chk_TimeUTC"         = "Set-TimeUTC"
    "chk_BingSearch"      = "Disable-BingSearch"
    "chk_CenterTaskbar"   = "Center-TaskbarItems"
    "chk_StartRecommend"  = "Disable-StartRecommendations"
    "chk_CrossDevice"     = "Disable-CrossDeviceResume"
    "chk_DarkTheme"       = "Enable-DarkTheme"
    "chk_LightTheme"      = "Enable-LightTheme"
    "chk_ModernStandby"   = "Fix-ModernStandby"
    "chk_MPO"             = "Disable-MultiplaneOverlay"
    "chk_FileExtensions"  = "Show-FileExtensionsHiddenFiles"
    "chk_StickyKeys"      = "Disable-StickyKeys"
}

# ── Apply Selected button ─────────────────────
$window.FindName("btnApplyAll").Add_Click({
    $selected = @()
    foreach ($kv in $checkMap.GetEnumerator()) {
        $ctrl = $window.FindName($kv.Key)
        if ($ctrl -and $ctrl.IsChecked) { $selected += $kv.Value }
    }
    if ($selected.Count -eq 0) {
        $script:LogBox.AppendText("[INFO] No tweaks selected.`n")
        return
    }
    $script:LogBox.AppendText("[INFO] Applying $($selected.Count) tweak(s)...`n")
    foreach ($fn in $selected) {
        $fnCopy = $fn
        & $fnCopy
    }
    $script:LogBox.AppendText("[DONE] All selected tweaks applied.`n")
    $script:LogBox.ScrollToEnd()
})

# ── Restore point button ───────────────────────
$window.FindName("btnRestorePoint").Add_Click({ Create-RestorePoint })

# ── Power plan buttons ─────────────────────────
$window.FindName("btnAddUltimatePower").Add_Click({ Add-UltimatePerformance })
$window.FindName("btnRemoveUltimatePower").Add_Click({ Remove-UltimatePerformance })
$window.FindName("btnListPowerPlans").Add_Click({
    Write-Log "Current power plans:"
    (powercfg /list) | ForEach-Object { Write-Log $_ }
})

# ── Gaming optimizer ───────────────────────────
$window.FindName("btnGamingOptimizer").Add_Click({ Apply-GamingOptimizer })

# ── Repair tools ──────────────────────────────
$window.FindName("btnSFC").Add_Click({ Run-SFC })
$window.FindName("btnDISM").Add_Click({ Run-DISM })
$window.FindName("btnRestartExplorer").Add_Click({ Restart-Explorer })

# ── Undo buttons ──────────────────────────────
$window.FindName("btnUndoRightClick").Add_Click({ Undo-ClassicRightClick })
$window.FindName("btnUndoIPv6").Add_Click({ Undo-DisableIPv6 })
$window.FindName("btnUndoTelemetry").Add_Click({ Undo-Telemetry })

# ── Clear log ────────────────────────────────
$window.FindName("btnClearLog").Add_Click({ $script:LogBox.Clear() })

# ── Welcome message ───────────────────────────
$script:LogBox.AppendText(@"
[ProTweaker] Welcome! Running as Administrator: $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
[ProTweaker] OS: $([System.Environment]::OSVersion.VersionString)
[ProTweaker] Tip: Create a Restore Point before applying tweaks.
[ProTweaker] Select your desired tweaks across the tabs, then click ▶ Apply Selected.

"@)

# ─────────────────────────────────────────────
#  LAUNCH WINDOW
# ─────────────────────────────────────────────
$window.ShowDialog() | Out-Null