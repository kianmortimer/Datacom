<#

Title:   get_groups_from_username.ps1
Author:  kian.mortimer@datacom.com
Date:    23/01/25
Version: 1.0

Description:
- Script to get the groups that a user belongs to and copy them to the clipboard

Workflow:
- Run this script and enter in the username of the user you wish to get the groups for
- The list will automatically be copied to the clipboard (Wow!)

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get Groups from Username"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get Active Directory Security Groups of a User              *"
Write-Host "* Enter the username of the user into the prompt below        *"
Write-Host "* Group list will be AUTOMATICALLY copied to the clipboard    *"
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
		Write-Host  " Enter username: $($user_input_substring)"
	} else {
		# If it's not the first loop; get the user input normally
		$user_input = Read-Host " Enter username" | ForEach-Object -Process { if ($_) { $_.Trim() } }
	}
	
	# Try-catch to make sure that an appropriate username was given
	try {
		# Get the groups from the specified user
		$members = Get-ADUser -Identity "$user_input" | ForEach-Object -Process { 
			Get-ADPrincipalGroupMembership -Identity $_.DistinguishedName | Select-Object Name }
	} catch { # If the above function (Get-ADUser) fails for any reason, it will be caught here
		# Advise the user, copy placeholder "None" to clipboard, and go back to start of main loop
		Write-Host " > User `"$user_input`" not found.`n"
		"None" | Set-Clipboard
		continue
	}
	
	# Sort the member list alphabetically
	$members = $members | Sort-Object -Property Name

	Write-Host
	
	# Format the list to output
	$members_string = ""
	foreach ($member in $members) {
		$members_string = $members_string + "$($member.Name)`n"
	}
	
	# Check if the member list is empty
	if (!$members_string) {
		# If list is empty: advise the user, copy placeholder "None" to clipboard, and go back to start of main loop
		Write-Host " > `"$user_input`" has no groups.`n"
		"None" | Set-Clipboard
	} else {
		# If list is not empty: paste the list and copy it to the clipboard
		Write-Host " > ($($members.count)) groups`n"
		Write-Host $members_string
		$members_string | Set-Clipboard
	}
}