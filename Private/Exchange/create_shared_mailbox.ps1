<#

Title:   create_shared_mailbox.ps1
Author:  kian.mortimer@datacom.com
Date:    24/01/25
Version: 1.2

Description:
- Script to create a shared mailbox

Workflow:
- Run this script and enter in the email address of the shared mailbox
- The mailbox will be created as per the standard process
- The only thing left to do is migrate the mailbox afterwards if needed
- If you make a mistake, you can just delete the mailbox from Exchange and the MBX group from AD

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Create Shared Mailbox"

# Name/Email Configuration
$valid_email_characters = @("A-Z", "0-9", ".", "-")
$min_length = 2
$max_length = 50
$valid_email_regex = "^[$($valid_email_characters -join '')]{$($min_length),$($max_length)}@?[A-Z.]*$"
$confirmation_array = @("Amy", "Ben", "Damien", "Edd", "Ehnel", "Elias", 
                            "Grace", "Jonathan", "Kian", "Gills", "Mills", "Luke",
                            "Mathew", "Rhys","Saniya", "Sid", "Taylor")

# Exchange On Premises Connection Configuration
$eop_server = "wlgprdmbx07.dia.govt.nz"
$eop_connection = "http://" + $eop_server + "/Powershell/"

# Create Mailbox Configuration
$email_domain = "dia.govt.nz"
$email_database = "EX16Mailbox-DB03"
$email_password = (ConvertTo-SecureString -String "Monday12" -AsPlainText -Force)
$email_location = "dia.govt.nz/Managed Objects/Production/Exchange/Resource Mailboxes/Shared Mailboxes"

# MBX Group Configuration
$mbx_group_location = "OU=Shared Mailbox Access Groups,OU=Groups,OU=Production,OU=Managed Objects,DC=dia,DC=govt,DC=nz"

# Print instructions to output
Write-Host
Write-Host " Create Shared Mailbox Script"
Write-Host " Enter the email address and voila!"
Write-Host

# Connect to Exchange Online
Write-Host " > Authenticating with Exchange Online..."
# This will automatically prompt for authentication through Microsoft
# Script will be terminated if authentication is not complete
Connect-ExchangeOnline
Write-Host " > Authenticated; continuing..."

$name = $null
$email = $null
# The initiation loop will continue until the email to use has been confirmed
:initiation while ($true) {
    Write-Host
	
	# Get the email address of the mailbox from user
	$email = Read-Host " Enter Email Address" | ForEach-Object -Process { if ($_) { $_.Trim() } }

    # Lower Boundary Test
    if ($null -eq $email -or $email.length -lt $min_length) {
        Write-Host " ! Minimum length -> [$($min_length)]"
        continue
    } 
    # Upper Boundary Test
    elseif ($(($email -split '@')[0]).length -gt $max_length) {
        Write-Host " ! Maximum length -> [$($max_length)]"
        continue
    } 
    # Email structure must match the Regular Expression set in the configuration
    elseif ($email -notmatch $valid_email_regex) {
        Write-Host " ! Allowed characters -> [@] [$($valid_email_characters -join '] [')]"
        continue
    }
    # Add domain if not present in email provided
    elseif ($email -notlike "*@*") {
        $email = $email + "@" + $email_domain
    }

    # Format $name and $email for continued use later
    # $name is the first part of the address
    $name = ($email -split '@')[0]
    # $email is the whole email address
    $email = $name + "@" + $email_domain

    Write-Host

    # We need to check that the mailbox doesn't exist before we can consider creating it
    Write-Host " > Checking for email conflicts..."
    # We check AD Objects rather than mailboxes because this encompasses all items including
    # mailboxes, users, distribution groups, groups, EOP and EOL
    # proxyAddresses attribute contains all the email addresses of an object, so we can be sure we caught all matches
    # We also check Name of objects so there is no other potential clash - accounting for any random edge cases
    $conflict = Get-ADObject -Filter "proxyAddresses -like '*smtp:$email*' -or Name -like '$name'" -IncludeDeletedObjects -ResultSetSize 1 -Properties *
    if ($null -ne $conflict) {
        Write-Host " [CONFLICT FOUND] : $($conflict.Name) : $($conflict.mail) : $($conflict.ObjectClass)"
        continue
    }
    # Check for conflicting MBX group
    # It is highly unlikely this would ever be a problem, but we account for all edge cases
    Write-Host " > Checking for AD group conflicts..."
    $mbx_group = "MBX_" + $name
    # AD groups actually can have separate Name and SamAccountName although it is usually the same, but we must check both
    $conflict = Get-ADGroup -Filter "Name -like '$mbx_group' -or SamAccountName -like '$mbx_group'" -ResultSetSize 1
    if ($null -ne $conflict) {
        Write-Host " [CONFLICT FOUND] : $($conflict.Name)"
        continue
    }
    Write-Host " > No conflict found; continuing...`n"
    Start-Sleep -Seconds 2

    # User to confirm the email and display name are correct
    Write-Host " [IMPORTANT] Please check and confirm the details"
    Write-Host " Name : $name"
    Write-Host " Email: $email"
    Write-Host

    # Require confirmation to avoid accidental creation - this is not the end of the world though
    # Get random name from the array so that it's different each time - user cannot autopilot
    $confirmation_choice = Get-Random -InputObject $confirmation_array
    $confirmation_input = Read-Host " [CONFIRM] Type the following name to confirm `n [$($confirmation_choice)]"
    # Check confirmation - case sensitive check
    $confirmed = $null -ne $confirmation_input -and $confirmation_input -clike $confirmation_choice
    if (!$confirmed) {
        Write-Host " [CANCELLED]"
        continue
    }
    Write-Host
    Write-Host " [CONFIRMED]"
    Write-Host

    # Exit the loop as the user has confirmed the creation
    break initiation
}

# Create Exchange On Premises Session
Write-Host " > Connecting to Exchange On Premises..."
# The default authentication is done automatically via Negotiation due to being internal
# This means we do not need to pass credentials to the new session
$eop_session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $eop_connection

# Start the Exchange On Premises Session
Write-Host " > Starting Exchange On Premises session..."
$imported_session = Import-PSSession $eop_session -DisableNameChecking -Prefix "EOP"

# Create the mailbox
Write-Host " > Creating mailbox..."
# DisplayName and the email addresses are taken automatically from the input Name
New-EOPMailbox -UserPrincipalName $email -Name $name -FirstName $name -Database $email_database -OrganizationalUnit $email_location -Password $email_password | Out-Null
Write-Host " > Mailbox [$email] has been created"
Write-Host
Start-Sleep -Seconds 2

# Check that the mailbox can be found before continuing
Write-Host " > Searching for the newly created mailbox..."
$is_created = $null
$is_created_count = 1
# Repeat until we get a response from Get-EOPMailbox
while ($null -eq $is_created) {
    Start-Sleep -Seconds 2
    #Write-Host " - Check [$is_created_count]"
    $is_created = Get-EOPMailbox -Identity $email
    $is_created_count++
}
Write-Host " > Mailbox confirmed; continuing..."
Write-Host
Start-Sleep -Seconds 2

# Run MessageCopy commands
Write-Host " > Setting mailbox MessageCopy settings to True..."
Set-EOPMailbox $email -MessageCopyForSentAsEnabled $true -MessageCopyForSendOnBehalfEnabled $true | Out-Null
Write-Host
Start-Sleep -Seconds 2

# Create MBX group to control access to the mailbox
Write-Host " > Creating MBX group..."
New-ADGroup -Name $mbx_group -SamAccountName $mbx_group -GroupCategory Security -GroupScope Global -DisplayName $mbx_group -Path $mbx_group_location -Description "Access to $email" | Out-Null
Write-Host " > MBX group [$mbx_group] has been created"
Write-Host
Start-Sleep -Seconds 2

# Check that the MBX group can be found before continuing
Write-Host " > Searching for the newly created MBX group..."
$is_created = $null
$is_created_count = 1
# Repeat until we get a response from Get-ADGroup
while ($null -eq $is_created) {
    Start-Sleep -Seconds 2
    #Write-Host " - Check [$is_created_count]"
    $is_created = Get-ADGroup -Identity $mbx_group
    $is_created_count++
}
Write-Host " > MBX group confirmed; continuing..."
Write-Host
Start-Sleep -Seconds 2

# Set the MBX group to Universal
Write-Host " > Setting group to Universal..."
Set-ADGroup $mbx_group -GroupScope "Universal" | Out-Null
Write-Host
Start-Sleep -Seconds 2

# Confirm MBX group is Universal
Write-Host " > Confirming MBX group is Universal..."
$is_universal = $false
$is_universal_count = 1
while (!$is_universal) {
    Start-Sleep -Seconds 2
    #Write-Host " - Check [$is_universal_count]"
    $is_universal = ((Get-ADGroup -Identity $mbx_group).GroupScope -like "Universal")
    $is_universal_count++
}
Write-Host " > MBX group is Universal; continuing..."
Write-Host
Start-Sleep -Seconds 2

# Enable MBX group Distribution Group
Write-Host " > Enabling MBX group as Distribution Group..."
# The group MUST be Universal for this command; that's why we checked
Enable-EOPDistributionGroup -Identity ((Get-ADGroup -Identity $mbx_group).DistinguishedName) | Out-Null
Start-Sleep -Seconds 2

# Hide MBX group from address lists
Write-Host " > Hiding MBX group from Global Address List..."
Get-EOPDistributionGroup -Identity ((Get-ADGroup -Identity $mbx_group).DistinguishedName) | Set-EOPDistributionGroup -HiddenFromAddressListsEnabled $true | Out-Null
Start-Sleep -Seconds 2

# Add the MBX group to Full Access to the mailbox
Write-Host " > Granting MBX group Full Access to mailbox..."
Add-EOPMailboxPermission -Identity $email -User $mbx_group -AccessRights FullAccess -InheritanceType All | Out-Null
Start-Sleep -Seconds 2

# Add the MBX group to Send As Access to the mailbox
Write-Host " > Granting MBX group Send As access to mailbox..."
# This process is different than Full Access. I don't know why, it just is.
Add-EOPADPermission -Identity $name -User $mbx_group -ExtendedRights "Send As" | Out-Null
Start-Sleep -Seconds 2

# Convert mailbox to shared mailbox
Write-Host " > Converting mailbox to shared mailbox..."
Get-EOPMailbox $email | Set-EOPMailbox -Type Shared | Out-Null
Start-Sleep -Seconds 2
Write-Host

# Terminate the Exchange On Premises session
Write-Host " > Terminating Exchange On Premises session..."
# If we don't do this, we may run out of allocated sessions and have to wait for automatic unlocking
Remove-PSSession $eop_session
Write-Host

# Tell the user that the process was successful
Write-Host "-----------------------------------"
Write-Host " [MAILBOX CREATION COMPLETE]"
Write-Host
Write-Host " MAILBOX  : $email"
Write-Host " MBX GROUP: $mbx_group"
Write-Host
Write-Host " You can check the results in EOP and AD"
Write-Host " - It is safe to delete the mailbox directly from EOP"
Write-Host "   and safe to delete the MBX group directly from AD"
Write-Host
Write-Host " The mailbox has NOT been migrated"
Write-Host " - If this is needed, it will need to be done separately"
Write-Host " - It may take 15-20 minutes to appear when migrating"
Write-Host

# Hold the window open after script completion
Read-Host -Prompt " Press [Enter] to exit"