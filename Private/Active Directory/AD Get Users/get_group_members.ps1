<#

Title:   get_group_members.ps1
Author:  kian.mortimer@datacom.com
Date:    07/06/24
Version: 1.6

Description: 
- Script to get the members of an AD group and copy them to the clipboard

How-to:
- Ever been asked for a list of users that have access to a mailbox?
- This script aims to make the process easier by eliminating the need 
- to copy the members individually from Active Directory.

Workflow:
- Run this script and enter in the AD group you wish to get the members of
- For example: "MBX_tearatahi" would give you the list of users that have 
  access to that mailbox
- The list will automatically be copied to the clipboard (Wow!)

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get Members of an AD Group"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get Members of an Active Directory Security Group           *"
Write-Host "* Enter the name of the AD group into the prompt below        *"
Write-Host "* Member list will be AUTOMATICALLY copied to the clipboard   *"
Write-Host "*                                                             *"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host

# First loop will auto-paste the user's clipboard
$first = $true

# The main loop, will keep repeating until script is terminated
:mainLoop while ($true) {
	Write-Host
	
	# Check whether this is the first loop
	if ($first) {
		$first = $false
		# If it's the first loop; auto-paste the content in the user's clipboard
		$user_input = Get-Clipboard | ForEach-Object -Process { if ($_) { $_.Trim() } }
		$user_input_substring = $user_input.Substring(0, [Math]::Min($user_input.Length, 50))
		Write-Host  " Enter group name: $($user_input_substring)"
	} else {
		# If it's not the first loop; get the user input normally
		$user_input = Read-Host " Enter group name" | ForEach-Object -Process { if ($_) { $_.Trim() } }
	}
	
	# Try-catch to make sure that an appropriate AD group was given
	# This will also catch stupid searches such as "Domain Users" which have way too many members
	try {
		# Get the members and all their attributes from the specified AD group
		$members = Get-ADGroupMember -Identity "$user_input" | ForEach-Object -Process { 
			Get-ADObject -Identity $_.DistinguishedName -Properties * }
	} catch { # If the above function (Get-ADGroupMember) fails for any reason, it will be caught here
		# Advise the user, copy placeholder "None" to clipboard and go back to start of main loop
		Write-Host " > AD group `"$user_input`" not found.`n"
		"None" | Set-Clipboard
		continue
	}
	
	# Sort the member list alphabetically
	$members = $members | Sort-Object -Property Name
	
	# Split the member list into users and any other members
	$members_user = $members | Where-Object { $_.ObjectClass -eq "user" }
	$members_other = $members | Where-Object { $_.ObjectClass -ne "user" }

	Write-Host
	
	# Format the list to output
	$members_string = ""
	
	# Put users into the list
	foreach ($user in $members_user) {
		$user = Get-ADUser -Identity $user.DistinguishedName -Properties *
		$members_string = $members_string + "$($user.Name)$( if ($user.Enabled -ne "True") { " [Disabled Account]" } )`n" #
	}
	# Put other member types into list if applicable
	if ($members_other.count -gt 0) {
		$members_string = $members_string + "`n"
		foreach ($other in $members_other) {
			$members_string = $members_string + "$($other.Name)`n"
		}
	}
	
	# Check if the member list is empty
	if (!$members_string) {
		# If list is empty, advise user and copy placeholder "None" to clipboard
		Write-Host " > `"$user_input`" has no members.`n"
		"None" | Set-Clipboard
	} else {
		# If list is not empty, paste the list and copy it to the clipboard
		#$members_string = " > ($($members.count)) members`n" + $members_string
		Write-Host " > ($($members.count)) members`n"
		Write-Host $members_string
		$members_string | Set-Clipboard
	}
}

# Insert Eminem and Dr Dre headbanging in the lambo gif