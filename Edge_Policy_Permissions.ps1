<#
============================================================
Title:      Lab Edge Policy Cleanup and Permission Lockdown
Author:     Matthew Maher
Date:       03/05/2026

Purpose:
Remove existing Microsoft Edge policy settings and recreate
the policy keys with restricted permissions for lab testing.

Intended Use:
Designed for lab devices, Azure VMs, test machines, or build
environments where Edge policies need to be cleared and
temporarily prevented from reapplying.

Configuration Summary:
- User Edge Policy:    Removed, recreated, and locked
- System Edge Policy:  Removed, recreated, and locked
- Backup Location:    C:\edgeregbackup
- Microsoft Account:  Enabled
- OneDrive Personal:  Allowed

Notes:
- Run PowerShell as Administrator.
- Intended for lab or temporary troubleshooting use only.
- This may prevent Intune, GPO, or SYSTEM-level services from
  reapplying Edge policy settings.
- Remove the deny permissions or delete the recreated keys when
  normal device management is required again.
============================================================
#>

$Username      = $env:USERNAME
$BackupPath    = "C:\edgeregbackup"

$UserEdgeKey   = "HKCU:\Software\Policies\Microsoft\Edge"
$SystemEdgeKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null

function Lock-RegKey {
    param ([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Warning "Cannot lock missing key: $Path"
        return
    }

    Write-Output "Locking: $Path"

    $acl = Get-Acl $Path
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
        "SYSTEM",
        "SetValue, CreateSubKey, Delete, ChangePermissions",
        "Deny"
    )

    $acl.AddAccessRule($rule)
    Set-Acl -Path $Path -AclObject $acl
}

function Reset-EdgePolicyKey {
    param (
        [string]$Path,
        [string]$ExportPath,
        [string]$RegExportPath
    )

    if (Test-Path $Path) {
        Write-Output "Backing up: $RegExportPath"
        reg export $RegExportPath $ExportPath /y | Out-Null

        Write-Output "Removing: $Path"
        Remove-Item $Path -Recurse -Force
    }
    else {
        Write-Output "No existing key found: $Path"
    }

    Write-Output "Recreating and locking: $Path"
    New-Item -Path $Path -Force | Out-Null
    Lock-RegKey -Path $Path
}

Reset-EdgePolicyKey `
    -Path $UserEdgeKey `
    -ExportPath "$BackupPath\Edge_User_Backup_$Username.reg" `
    -RegExportPath "HKCU\Software\Policies\Microsoft\Edge"

Reset-EdgePolicyKey `
    -Path $SystemEdgeKey `
    -ExportPath "$BackupPath\Edge_System_Backup.reg" `
    -RegExportPath "HKLM\SOFTWARE\Policies\Microsoft\Edge"

$AccountPolicyPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\Device\Accounts"
New-Item -Path $AccountPolicyPath -Force | Out-Null
Set-ItemProperty -Path $AccountPolicyPath `
    -Name "AllowMicrosoftAccountConnection" `
    -Value 1 `
    -Force

$OneDrivePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
New-Item -Path $OneDrivePolicyPath -Force | Out-Null
Remove-ItemProperty -Path $OneDrivePolicyPath `
    -Name "DisablePersonalSync" `
    -ErrorAction SilentlyContinue

Set-ItemProperty -Path $OneDrivePolicyPath `
    -Name "DisablePersonalSync" `
    -Value 0 `
    -Type DWord

Write-Output "Done."