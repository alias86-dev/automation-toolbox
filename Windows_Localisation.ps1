<#
============================================================
Title:      Windows Localisation Configuration
Author:     Matthew Maher
Date:       03/05/2026

Purpose:
Configure Windows language, keyboard, and regional settings 
to UK standards (en-GB) while allowing flexibility for 
region-specific deployments.

Intended Use:
Designed for Azure Virtual Machines deployed in US regions,
where default localisation is often en-US and needs to be 
standardised to UK settings.

Configuration Summary:
- UI Language:        English (United Kingdom) [en-GB]
- User Culture:       en-GB (date, time, currency formats)
- System Locale:      en-GB (non-Unicode applications)
- Keyboard Layout:    UK (0809:00000809)
- Region:             Ireland (GeoId: 68)
- Time Zone:          GMT Standard Time

Notes:
- A sign-out or restart is required for UI language changes 
  to fully apply.
- Script is safe for repeat execution (idempotent).
- Compatible with Intune, Azure VM custom scripts, and 
  manual execution.

============================================================
#>

# -------------------------------
# Target values
# -------------------------------
$Lang     = "en-GB"
$Keyboard = "0809:00000809"
$GeoId    = 68
$TimeZone = "GMT Standard Time"

# -------------------------------
# Language and keyboard
# -------------------------------
$langList = New-WinUserLanguageList $Lang
$langList[0].InputMethodTips.Clear()
$langList[0].InputMethodTips.Add($Keyboard)

Set-WinUserLanguageList $langList -Force
Set-WinUILanguageOverride -Language $Lang   # Key for UI language

# -------------------------------
# Region and format settings
# -------------------------------
Set-Culture $Lang
Set-WinSystemLocale $Lang
Set-WinHomeLocation -GeoId $GeoId
Set-TimeZone -Id $TimeZone

# -------------------------------
# Copy to system / new users
# -------------------------------
if (Get-Command Copy-UserInternationalSettingsToSystem -ErrorAction SilentlyContinue) {
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true
}

# -------------------------------
# Verification output
# -------------------------------
$result = [PSCustomObject]@{
    UILanguage      = (Get-UICulture).Name
    UIOverride      = try { (Get-WinUILanguageOverride).Name } catch { $null }
    UserCulture     = (Get-Culture).Name
    SystemLocale    = (Get-WinSystemLocale).Name
    Region          = (Get-WinHomeLocation).DisplayName
    TimeZone        = (Get-TimeZone).Id
    KeyboardLayouts = ((Get-WinUserLanguageList).InputMethodTips -join ', ')
    RestartRequired = $true
}

$result | Format-List