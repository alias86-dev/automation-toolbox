<#
============================================================
Title:      Lab Local Admin Account Creation
Author:     Matthew Maher
Date:       03/05/2026

Purpose:
Remove and recreate a local administrator account for lab,
testing, or temporary setup use.

Intended Use:
Designed for lab devices, Azure VMs, test machines, or build
environments where a known local admin account is required.

Configuration Summary:
- Local Username:     admin
- Account Type:       Local User
- Group Membership:   Local Administrators
- Existing Account:   Removed if already present
- Profile Folder:     Removed if already present

Notes:
- Run PowerShell as Administrator.
- Removing the user does not always remove the profile folder,
  so the profile path is removed separately.
- Only use a known password in secure lab or temporary setups.
- Change or disable this account after setup if no longer needed.
============================================================
#>

$Username = "admin"
$PlainPassword = "admin"
$ProfilePath = "C:\Users\$Username"

# Remove local user if it already exists
if (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue) {
    Remove-LocalUser -Name $Username
}

# Remove old profile folder if it exists
if (Test-Path $ProfilePath) {
    Remove-Item $ProfilePath -Recurse -Force
}

# Create secure password object
$Password = ConvertTo-SecureString $PlainPassword -AsPlainText -Force

# Create local user
New-LocalUser `
    -Name $Username `
    -Password $Password `
    -FullName "Local Admin" `
    -Description "Local lab administrator account"

# Add user to local Administrators group
Add-LocalGroupMember -Group "Administrators" -Member $Username

# Confirm account and admin membership
Get-LocalUser -Name $Username
Get-LocalGroupMember -Group "Administrators" | Where-Object Name -like "*$Username*"