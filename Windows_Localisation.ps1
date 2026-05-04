<#
============================================================
Title:      Windows Localisation Remediation (Azure VM Fix)
Author:     Matthew Maher
Date:       03/05/2026

Purpose:
Remediate incorrect US-based localisation settings applied to Azure Virtual Machines during deployment.
This script forces UK regional, language, and keyboard settings to ensure consistency across environments.

Intended Use:
Designed for Azure VMs provisioned in US regions (or via images/templates) where default settings are:
- en-US language
- US keyboard layout
- US regional formats

This script acts as a post-deployment fix/patch to align systems with UK standards.

Configuration Summary:
- UI Language:        English (United Kingdom) [en-GB]
- User Culture:       en-GB (date, time, currency formats)
- System Locale:      en-GB (non-Unicode applications)
- Keyboard Layout:    UK (0809:00000809)
- Region:             Ireland (GeoId: 68)
- Time Zone:          GMT Standard Time

Notes:
- Intended as a remediation script, not initial build config.
- Safe for repeat execution (idempotent).
- A sign-out or restart is required for full UI changes.
- Can be deployed via Intune, Azure Custom Script Extension, or run manually post-build.
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