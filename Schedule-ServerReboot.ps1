<#
============================================================
Title:      Out-of-Hours Server Rebooter
Author:     Matthew Maher
Date:       03/05/2026

Purpose:
Create a one-time scheduled task to forcefully reboot the server out of hours.

Intended Use:
Designed for servers, Azure VMs, or test machines that require a clean, 
automated restart during non-business hours without an active administrator presence.

Configuration Summary:
- Target Reboot Time:  19:30 (7:30 PM)
- Action:              shutdown.exe /r /f /t 0
- Task Name:           RebootAt730PM
- Run Level:           Highest (Administrator)

Notes:
- Run PowerShell as Administrator.
- The scheduled task is configured to run exactly once.
- To change the reboot time, modify the $ScheduledTime variable.
============================================================
#>

.LINK
    https://github.com/[YourUsername]/[YourRepository]

.NOTES
    This script must be run with Administrator privileges to successfully register the Scheduled Task.
#>

# Define the fixed time for the reboot
$ScheduledTime = (Get-Date -Hour 19 -Minute 30 -Second 0)

# Create a one-time scheduled task trigger at 7:30 PM
$TimeTrigger = New-ScheduledTaskTrigger -Once -At $ScheduledTime

# Define the action to restart the machine
$Action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /f /t 0"

# Register the task with a name, user, and description
$TaskName = "RebootAt730PM"
Register-ScheduledTask -TaskName $TaskName -Trigger $TimeTrigger -Action $Action -Description "Reboots the server at 7:30 PM" -RunLevel Highest -Force

# Output the scheduled time for verification
Write-Output "The machine is scheduled to reboot at $ScheduledTime."