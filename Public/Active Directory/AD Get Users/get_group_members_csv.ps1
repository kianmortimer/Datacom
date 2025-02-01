<#

Title:   get_group_members_csv.ps1
Author:  kian.mortimer@datacom.com
Date:    12/07/24
Version: 4.1

Description: 
- Script to get the members of an AD group and write them to an Excel Spreadsheet
- Spreadsheet is a CSV file - plain text file that Jumphost can write to and Excel can read
- It is Tab delimited and not Comma delimited as commas won't automatically populate to
  new columns in Excel without you telling it to (I don't know why, it makes no sense)

How-to:
- Ever been asked for a list of users that have access to a mailbox?
- This script aims to make the process easier by eliminating the need 
- to copy the members individually from Active Directory.

Workflow:
- Run this script and enter in the AD group you wish to get the members of
- For example: "MBX_tearatahi" would give you the list of users that have 
  access to that mailbox
- A CSV containing all the members of the AD group
- The CSV contains more information about each member (username, email, last login, etc.)

Help:
- Google the functions or ask me what's up
- Microsoft Learn is a good online tool - https://learn.microsoft.com/en-us/powershell/
- Good luck soldier o7

#>

# Change window title
$host.ui.RawUI.WindowTitle = "Get Members of an AD Group & Export to CSV"

# Print instructions to output
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host "* Get Members of an Active Directory Security Group               *"
Write-Host "* Enter the name of the AD group into the prompt below            *"
Write-Host "* Member list will be exported to Exported Member Lists folder    *"
Write-Host "*                                                                 *"
Write-Host "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
Write-Host

# Format CSV fields
$fields = "ID`tName`tEmail`tUsername`tType`tActive`tLast Activity`n"

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
	
	$ad_group = $user_input
	
	# Try-catch to make sure that an appropriate AD group was given
	# This will also catch stupid searches such as "Domain Users" which have way too many members
	try {
		# Get the members and all their attributes from the specified AD group
		$members = Get-ADGroupMember -Identity "$ad_group" | ForEach-Object -Process { 
			Get-ADObject -Identity $_.DistinguishedName -Properties * }
	} catch { # If the above function (Get-ADGroupMember) fails for any reason, it will be caught here
		# Advise the user and go back to start of main loop
		# Nothing from this group will be added to the CSVs
		Write-Host " ! AD group $ad_group not found.`n"
		continue
	}
	
	Write-Host " > Sorting list..."
	
	# Sort the member list alphabetically
	$members = $members | Sort-Object -Property Name
	
	# Split the member list into users and any other members
	$members_user = $members | Where-Object { $_.ObjectClass -eq "user" }
	$members_other = $members | Where-Object { $_.ObjectClass -ne "user" }
	
	# Format the list to output
	$members_string = $fields
	
	# Counter for listing the members
	$count = 1
	
	Write-Host " > Formatting list... [Users]"

    # DateTime format
    $datetime_format = "dd/MM/yyyy  HH:mm:ss"
	
	# Put users into the list
	foreach ($user in $members_user) {
		$user = Get-ADUser -Identity $user.DistinguishedName -Properties *
		# Get the last logon date
		# If there is an attribute containing a FileTime, use that and convert it,
		# otherwise take a date from one of the other attributes
		$last_logon = if ($user.LastLogon) { 
				[datetime]::FromFileTime($user.LastLogon).ToString($datetime_format) }
			elseif ($user.LastLogonTimestamp) { 
				[datetime]::FromFileTime($user.LastLogonTimestamp).ToString($datetime_format) }
			elseif ($user.LastLogonDate) { $user.LastLogonDate } 
			elseif ($user.Modified) { $user.Modified }
			elseif ($other.WhenChanged) { $other.WhenChanged }
			else { "" }
		# Format object properties into CSV record
		$results = "`t$($user.Name)`t$($user.EmailAddress)`t$($user.SAMAccountName)`t$($user.ObjectClass)`t$($user.Enabled)`t$($last_logon)`n"
		# Add to the CSV for this group
		$members_string = $members_string + $count + $results 
		$count ++
	}
	
	Write-Host " > Formatting list... [Objects]"
	
	# Put other member types into list if applicable
	if ($members_other.count -gt 0) {
		foreach ($other in $members_other) {
			# Get the last logon date
			# If there is an attribute containing a FileTime, use that and convert it,
			# otherwise take a date from one of the other attributes
			$last_logon = if ($user.LastLogon) { 
					[datetime]::FromFileTime($user.LastLogon).ToString($datetime_format) }
				elseif ($user.LastLogonTimestamp) { 
					[datetime]::FromFileTime($user.LastLogonTimestamp).ToString($datetime_format) }
				elseif ($user.LastLogonDate) { $user.LastLogonDate } 
				elseif ($user.Modified) { $user.Modified }
				elseif ($other.WhenChanged) { $other.WhenChanged }
				else { "" }
			# Format object properties into CSV record
			$results = "`t$($other.Name)`t`t`t$($other.ObjectClass)`t`t$($last_logon)`n"
			# Add to the CSV for this group
			$members_string = $members_string + $count + $results
			$count ++
		}
	}
	
	Write-Host " > Exporting list..."
	
	# Check if the member list is empty
	if (!$members_string) {
		# If list is empty, advise user
		Write-Host " ! AD group $ad_group has no members.`n"
	} else {
		# If list is not empty, export to CSV
		$members_string > "Exported Member Lists\$($ad_group) $(Get-Date -Format 'dd-MM-yy').csv"
		Write-Host " >>> Exported Member Lists\$($ad_group) $(Get-Date -Format 'dd-MM-yy').csv"
	}
}

# Insert Kermit sipping tea .jpg