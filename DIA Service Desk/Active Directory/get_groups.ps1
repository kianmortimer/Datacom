<#

Title:   get_groups_from_username.ps1
Author:  kian.mortimer@datacom.com
Date:    15/03/25
Version: 2.0

Description:
- Script to get the groups that an object belongs to and copy them to the clipboard

Workflow:
- Run this script and enter in the identifier of the object (i.e. username)
- The group list will automatically be copied to the clipboard (Wow!)

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get Groups"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get Active Directory Security Groups of an Object           *"
Write-Host "* Enter the identity of the object into the prompt below      *"
Write-Host "* Group list will be AUTOMATICALLY copied to the clipboard    *"
Write-Host "*                                                             *"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host

Write-Host " Identity can be one of the following:"
Write-Host " - Username of a user"
Write-Host " - Name of a device"
Write-Host " - Name of a group"

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
		Write-Host  " Enter identity: $($user_input_substring)"
	} else {
		# If it's not the first loop; get the user input normally
		$user_input = Read-Host " Enter identity" | ForEach-Object -Process { if ($_) { $_.Trim() } }
	}
	
	# Try-catch to make sure that an appropriate username was given
	try {
		# Get the groups from the specified user
        $object = Get-ADObject -Filter "SAMAccountName -eq '$user_input' -or SAMAccountName -eq '$user_input$'"
        $groups = Get-ADPrincipalGroupMembership -Identity $object | Select-Object Name
	} catch { # If the above function (Get-ADObject) fails for any reason, it will be caught here
		# Advise the user, copy placeholder "None" to clipboard, and go back to start of main loop
		Write-Host " > Identity `"$user_input`" not found.`n"
		"None" | Set-Clipboard
		continue
	}
	
	# Sort the group list alphabetically
	$groups = $groups | Sort-Object -Property Name

	Write-Host
	
	# Format the list to output
	$groups_string = ""
	foreach ($group in $groups) {
		$groups_string = $groups_string + "$($group.Name)`n"
	}
	
	# Check if the group list is empty
	if (!$groups_string) {
		# If list is empty: advise the user, copy placeholder "None" to clipboard, and go back to start of main loop
		Write-Host " > `"$user_input`" has no groups.`n"
		"None" | Set-Clipboard
	} else {
		# If list is not empty: paste the list and copy it to the clipboard
		Write-Host " > ($($groups.count)) groups`n"
		Write-Host $groups_string
		$groups_string | Set-Clipboard
	}
}