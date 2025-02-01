<#

Title:   get_group_members_excel.ps1
Author:  kian.mortimer@datacom.com
Date:    25/06/24
Version: 2.1

Description: 
- Script to get the members of an AD group and write them to an Excel Spreadsheet
- Spreadsheet is a CSV file - plain text file that Jumphost can write to and Excel can read
- It is Tab delimited and not Comma delimited as commas won't automatically populate to
- new columns in Excel without you telling it to (I don't know why, it makes no sense)

How-to:
- Ever been asked for a list of users that have access to a mailbox?
- This script aims to make the process easier by eliminating the need 
- to copy the members individually from Active Directory.

Workflow:
- Run this script and enter in the AD group you wish to get the members of
- For example: "MBX_tearatahi" would give you the list of users that have 
- access to that mailbox
- The list will automatically be copied to the clipboard (Wow!)
- The list will also be exported to a CSV for use with Excel

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
Write-Host "* Member list will be written to CSV for use with Excel       *"
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
		Write-Host  " Enter group name: $($user_input)"
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
		Write-Host "`n > AD group not found.`n"
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
	$members_string = "ID`tName`tEmail`tUsername`tActive`n"
	
	# Counter for listing the members
	$count = 1
	
	# Put users into the list
	foreach ($user in $members_user) {
		$user = Get-ADUser -Identity $user.DistinguishedName -Properties *
		$members_string = $members_string + "$count`t$($user.Name)`t$($user.EmailAddress)`t$($user.SAMAccountName)`t$($user.Enabled)`n" #
		$count ++
	}
	# Put other member types into list if applicable
	if ($members_other.count -gt 0) {
		foreach ($other in $members_other) {
			$members_string = $members_string + "$count`t$($other.Name)`tN/A`tN/A`tN/A`n"
			$count ++
		}
	}
	
	# Check if the member list is empty
	if (!$members_string) {
		# If list is empty, advise user and copy placeholder "None" to clipboard
		Write-Host "`n > AD group has no members.`n"
		"None" | Set-Clipboard
	} else {
		# If list is not empty, paste the list and copy it to the clipboard, and export to CSV
		Write-Host $members_string
		$members_string | Set-Clipboard
		$members_string > "Exported Member Lists\$($user_input) $(Get-Date -Format 'dd-MM-yy').csv"
		Write-Host "`n Exported Member List to:`n >>> Exported Member Lists\$($user_input) $(Get-Date -Format 'dd-MM-yy').csv"
	}
}

# Insert Eminem and Dr Dre headbanging in the lambo gif