<#

Title:   enable_messagecopy_settings.ps1
Author:  kian.mortimer@datacom.com
Date:    20/02/25
Version: 1.0

Description:
- Script to set the MessageCopy settings to True
- The settings enable the ability to send from the shared mailbox

Workflow:
- Run this script and log in to Exchange Online
- Enter in the email address of the shared mailbox
- The MessageCopy settings will be enabled

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Enable MessageCopy Settings"

# Print instructions to output
Write-Host
Write-Host " Enable MessageCopy Settings"
Write-Host " Enter the email address and voila!"
Write-Host

# Connect to Exchange Online
Write-Host " > Authenticating with Exchange Online..."
# This will automatically prompt for authentication through Microsoft
# Script will be terminated if authentication is not complete
Connect-ExchangeOnline
Write-Host " > Authenticated; continuing..."

$email = $null
# The initiation loop will continue until the email to use has been confirmed
:initiation while ($true) {
    Write-Host
	
	# Get the email address of the mailbox from user
	$email = Read-Host " Enter email address" | ForEach-Object -Process { if ($_) { $_.Trim() } }

    # Lower Boundary Test
    if ($null -eq $email) {
        Write-Host " ! No input"
        continue
    }
	
	# Check current status
	Get-Mailbox -Identity $email | Select-Object MessageCopyForSentAsEnabled,MessageCopyForSendOnBehalfEnabled |fl
	# Run MessageCopy commands
	Write-Host " > Setting -MessageCopyForSentAsEnabled to True..."
	Set-Mailbox $email -MessageCopyForSentAsEnabled $true 
	Write-Host " > Setting -MessageCopyForSendOnBehalfEnabled to True..."
	Set-Mailbox $email -MessageCopyForSendOnBehalfEnabled $true
	
	# Confirm the result
	Get-Mailbox -Identity $email | Select-Object MessageCopyForSentAsEnabled,MessageCopyForSendOnBehalfEnabled |fl
	
	# Hold the window open after script completion
	Read-Host -Prompt " Press [Enter] to continue"
}